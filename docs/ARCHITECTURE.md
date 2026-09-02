# Stage 1 वास्तुकला

उत्पादन पक्षमा अहिले केवल तटस्थ orchestration आधार छ। semantic state एउटै invocation को context भित्र बस्छ। observability state ले semantic निर्णय चलाउन पाउँदैन। validation असफल भएमा partial result फर्काइँदैन।

`SourceLanguageCatalog` को पाठ presentation तहमा मात्र समाधान हुन्छ। rank, unrank, cache key वा क्यानोनिकल क्रमका लागि string प्रयोग हुँदैन; `canonicalIndex` मात्र प्रयोग हुन्छ।

Stage 2 अघि कुनै ऐतिहासिक legacy path थप्न निषेध गरिएको छ।
