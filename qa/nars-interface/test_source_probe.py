import pathlib, tempfile, unittest
from source_probe import probe
class SourceProbeTests(unittest.TestCase):
    def test_candidates_with_exact_locations(self):
        with tempfile.TemporaryDirectory() as d:
            p=pathlib.Path(d)/'main.c'
            p.write_text('int main(int argc,char **argv) { return 0; }\n// WM_COPYDATA\n',encoding='utf-8')
            result=probe(pathlib.Path(d))
            self.assertEqual(result['source_files'],1)
            self.assertTrue(any(x['line']==1 for x in result['matches']['startup_command_line']))
            self.assertTrue(any(x['line']==2 for x in result['matches']['windows_ipc']))
            self.assertEqual(result['cli_supported'],'UNDETERMINED')
            self.assertFalse(result['native_executed'])
    def test_missing(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(ValueError,'SOURCE_UNAVAILABLE'):probe(pathlib.Path(d))
    def test_file_budget(self):
        with tempfile.TemporaryDirectory() as d:
            (pathlib.Path(d)/'a.c').write_text('int a;',encoding='ascii')
            with self.assertRaisesRegex(ValueError,'SOURCE_TOO_LARGE'):probe(pathlib.Path(d),max_bytes=2)
    def test_file_limit(self):
        with tempfile.TemporaryDirectory() as d:
            for name in ('a.c','b.h'):(pathlib.Path(d)/name).write_text('x',encoding='ascii')
            with self.assertRaisesRegex(ValueError,'SOURCE_TOO_MANY_FILES'):probe(pathlib.Path(d),max_files=1)
if __name__=='__main__':unittest.main()
