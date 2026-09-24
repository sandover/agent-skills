"""Check that host source bundles are exact, named, and leave the source checkout alone."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/windows-vm-source-bundle'


def git(repo, *arguments):
    return subprocess.run(['git', '-C', str(repo), *arguments], check=True,
                          capture_output=True, text=True).stdout.strip()


class SourceBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'source repo'
        self.repo.mkdir()
        git(self.repo, 'init', '--quiet')
        git(self.repo, 'config', 'user.name', 'Source Bundle Test')
        git(self.repo, 'config', 'user.email', 'source-bundle@example.invalid')
        (self.repo / 'tracked.txt').write_text('base\n')
        git(self.repo, 'add', 'tracked.txt')
        git(self.repo, 'commit', '--quiet', '-m', 'base')
        self.base = git(self.repo, 'rev-parse', 'HEAD')
        (self.repo / 'tracked.txt').write_text('candidate\n')
        git(self.repo, 'commit', '--quiet', '-am', 'candidate')
        self.candidate = git(self.repo, 'rev-parse', 'HEAD')

    def run_helper(self, candidate=None, base=None):
        environment = dict(os.environ, TMPDIR=str(self.root))
        return subprocess.run(
            [str(SCRIPT), str(self.repo), candidate or self.candidate, base or self.base],
            capture_output=True, text=True, env=environment)

    def test_bundle_advertises_candidate_and_preserves_dirty_source(self):
        (self.repo / 'tracked.txt').write_text('dirty unstaged\n')
        (self.repo / 'staged.txt').write_text('staged version\n')
        git(self.repo, 'add', 'staged.txt')
        (self.repo / 'staged.txt').write_text('staged plus unstaged\n')
        (self.repo / 'untracked.txt').write_text('untracked\n')
        before_status = git(self.repo, 'status', '--porcelain=v1')
        before_refs = git(self.repo, 'show-ref')
        before_diff = git(self.repo, 'diff', '--binary')
        before_cached_diff = git(self.repo, 'diff', '--cached', '--binary')

        result = self.run_helper()

        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output['status'], 'bundle_created')
        self.assertEqual(output['candidate_sha'], self.candidate)
        self.assertEqual(output['guest_base_sha'], self.base)
        self.assertEqual(output['advertised_ref'], 'refs/heads/candidate')
        bundle = Path(output['bundle_path'])
        self.assertTrue(bundle.is_file())
        self.assertEqual(git(self.repo, 'bundle', 'list-heads', str(bundle)),
                         f"{self.candidate} refs/heads/candidate")
        git(self.repo, 'bundle', 'verify', str(bundle))

        self.assertEqual(git(self.repo, 'status', '--porcelain=v1'), before_status)
        self.assertEqual(git(self.repo, 'show-ref'), before_refs)
        self.assertEqual(git(self.repo, 'diff', '--binary'), before_diff)
        self.assertEqual(git(self.repo, 'diff', '--cached', '--binary'), before_cached_diff)
        self.assertEqual((self.repo / 'tracked.txt').read_text(), 'dirty unstaged\n')
        self.assertEqual((self.repo / 'staged.txt').read_text(), 'staged plus unstaged\n')
        self.assertEqual((self.repo / 'untracked.txt').read_text(), 'untracked\n')
        self.assertFalse((bundle.parent / 'export.git').exists())

        second = self.run_helper()
        self.assertEqual(second.returncode, 0, second.stderr)
        second_bundle = Path(json.loads(second.stdout)['bundle_path'])
        self.assertNotEqual(second_bundle, bundle)
        self.assertTrue(second_bundle.is_file())

    def test_rejects_non_ancestor_base(self):
        git(self.repo, 'checkout', '--quiet', '--orphan', 'unrelated')
        git(self.repo, 'rm', '-rf', '--quiet', '.')
        (self.repo / 'other.txt').write_text('other root\n')
        git(self.repo, 'add', 'other.txt')
        git(self.repo, 'commit', '--quiet', '-m', 'unrelated candidate')
        unrelated = git(self.repo, 'rev-parse', 'HEAD')

        result = self.run_helper(candidate=unrelated, base=self.base)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('guest base is not an ancestor', result.stderr)
        self.assertEqual(list(self.root.glob('windows-source-*')), [])

    def test_equal_candidate_and_base_needs_no_bundle(self):
        result = self.run_helper(candidate=self.base, base=self.base)

        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output, {
            'status': 'already_present',
            'bundle_path': None,
            'advertised_ref': None,
            'candidate_sha': self.base,
            'guest_base_sha': self.base,
        })
        self.assertEqual(list(self.root.glob('windows-source-*')), [])

    def test_rejects_short_ids_and_non_commit_objects(self):
        short = self.run_helper(candidate=self.candidate[:12])
        self.assertNotEqual(short.returncode, 0)
        self.assertIn('full 40- or 64-character commit ID', short.stderr)

        tree = git(self.repo, 'rev-parse', f'{self.candidate}^{{tree}}')
        non_commit = self.run_helper(candidate=tree)
        self.assertNotEqual(non_commit.returncode, 0)
        self.assertIn('^{commit}', non_commit.stderr)


if __name__ == '__main__':
    unittest.main()
