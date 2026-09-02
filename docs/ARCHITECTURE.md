# Birinci mərhələ arxitekturası

Bu mərhələnin məqsədi gələcək tarixi yamaqları qabaqcadan yaratmadan neytral, amma sonradan böyüdülə bilən qabıq hazırlamaqdır.

`MonsterContext` bir çağırışa məxsusdur. İki çağırış arasında semantik vəziyyət paylaşılmır. Hazırkı sahələr yalnız giriş, həyat dövrü, müşahidə və əsas yoxlama məlumatını saxlayır.

`MonsterDispatcher` qeydiyyatdan keçmiş mərhələ işləyicilərini müəyyən edilmiş ardıcıllıqla çağırır. Birinci mərhələdə semantik işləyici qeydiyyatdan keçirilmir; bu, gələcək qüsur və yamaqları qabaqcadan əlavə etməmək üçündür.

`MonsterValidationManager` yalnız neytral kontekst invariantlarını yoxlayır. `MonsterErrorBoundary` dispetçer və validator xətalarını deterministik kontekstlə sarıyır, lakin machine code-u və semantik qərarı dəyişmir. Bu qatların heç biri normativ cavab yaratmır və oracle-a müraciət etmir.

`MonsterMetrics` və `MonsterLog` müşahidə vəziyyətidir. Onların qiymətləri semantik qərarlara daxil edilmir.

Sınaq oracle-ı `tests/support/normative_oracle.rs` daxilində saxlanılır. İstehsal modulu onu import etmir və runtime fallback kimi istifadə edə bilməz.
