# पास्टाफेरियन पात्रो — PureScript + नेपाली

यो कार्यान्वयन रेखा शून्यबाट सुरु गरिएको स्वतन्त्र रेखा हो। यसको एकमात्र प्रोग्रामिङ भाषा PureScript हो र मानवले लेखेको क्यानोनिकल भाषा नेपाली हो। अर्को कार्यान्वयनबाट स्रोत, परीक्षण, परीक्षण सामग्री, अपेक्षित नतिजा, निर्मित तालिका, trace, hash वा checksum लिइएको छैन।

Stage 1 मा नेपाली `SourceLanguageCatalog` स्थिर गरिएको छ। Appendix A बाट परीक्षण-मात्र मानक oracle पूर्ण रूपमा पुनर्निर्माण गरिएको छ। मनपरी शुद्धताको पूर्णाङ्क गणना स्थानीय PureScript मा कार्यान्वयन गरिएको छ। भविष्यका ऐतिहासिक scar नल्याई तटस्थ monster context, dispatcher, validator, error wrapper र metrics shell तयार गरिएको छ।

semantic अवस्थाको स्वामित्व छुट्टै परीक्षण गरिएको छ। उत्पादन स्रोतमा `Effect`, `Ref`, FFI वा साझा परिवर्तनशील semantic अवस्था छैन। संयोजकीय memoization प्रत्येक invocation भित्र अपरिवर्तनीय `Map` का रूपमा सुरु हुन्छ, र gate अवस्था पनि प्रत्येक calendar invocation को छुट्टै कार्यात्मक value हो।

PureScript परीक्षण suite मा 54 वटा जाँच छन्। तिनमा BigInteger गणना, SAVE, दिनका count, ढुङ्गा snapshot, hidden/visible drops, bowl order, sauce isolation, gate gap, छोटो र फराकिलो छनोट, bounded composition, cutlet boundary filtering, month weaving, frozen catalog, प्रस्तुति mapping र bootstrap context isolation समेटिएका छन्।

हाल बाँकी एउटै प्रमाण वास्तविक build/test execution हो। उपलब्ध वातावरणमा `purs` र `spago` स्थापित छैनन्, र स्थानीय स्थापना प्रयास पनि पूरा हुन सकेन। त्यसैले स्रोत र परीक्षण कार्यान्वयन पूरा भए पनि Stage 1 लाई GREEN प्रमाणित गरिएको छैन। Stage 2 सुरु गरिएको छैन।
