# முதல் கட்ட சோதனை நிலை

## எதிர்பார்க்கப்படும் முடிவு

`sql/test/20_stage01_tests.sql` உள்ள அனைத்து assertions-உம் வெற்றியடைந்து transaction commit ஆக வேண்டும்.

## உண்மையான உள்ளூர் முடிவு

SQL execution நடத்தப்படவில்லை. இந்த artifact உருவாக்கப்பட்ட சூழலில் PostgreSQL server மற்றும் `psql` runtime கிடைக்கவில்லை. எனவே பச்சை execution முடிவு இருப்பதாகக் கூறப்படவில்லை.

## செய்யப்பட்ட நிலையான ஆய்வுகள்

- executable source file வகை SQL மட்டுமே;
- SQL function-களில் வேறு programming-language runtime declaration இல்லை;
- normative SQL-இல் floating-point வகை, logarithm, `power` அல்லது `bigint` gate-index சுருக்கம் இல்லை;
- production entry point test oracle schema-வை source code-ல் அழைக்கவில்லை;
- Stage 2–53 சார்ந்த legacy/patch code production-இல் முன்கூட்டியே சேர்க்கப்படவில்லை;
- package முன் repository இல்லாமல் full seed ஆக அமைக்கப்பட்டுள்ளது.

Execution முடிவு கிடைக்கும் வரை Stage 1 முழுமையாக நிறைவடைந்ததாகக் குறிக்கக்கூடாது.
