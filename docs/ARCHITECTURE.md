# Stage 1 वास्तुकला

उत्पादन पक्षमा अहिले केवल तटस्थ समन्वय आधार छ। semantic अवस्था एउटै invocation को context भित्र सीमित हुन्छ। अवलोकनका लागि राखिएका metrics वा trace ले semantic निर्णय चलाउन पाउँदैनन्। validation असफल भएमा अपूर्ण नतिजा फर्काइँदैन।

`SourceLanguageCatalog` को पाठ केवल प्रस्तुति तहमा समाधान हुन्छ। rank, unrank, cache key वा क्यानोनिकल क्रमका लागि स्थानीयकृत string प्रयोग हुँदैन; `canonicalIndex` मात्र प्रयोग हुन्छ।

मानक oracle उत्पादन monster बाट अलग परीक्षण-मात्र तह हो। Stage 1 को उत्पादन skeleton ले oracle लाई runtime मा बोलाउँदैन।

Stage 2 अघि कुनै ऐतिहासिक legacy path, scar, detour वा Patch 01–26 को उत्पादन code थप्न निषेध गरिएको छ।
