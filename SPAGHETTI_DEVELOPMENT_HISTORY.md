# स्पेगेटी विकास इतिहास

## Stage 1 — Bootstrap

### के बनाइयो
यो रेखा शून्यबाट सुरु गरियो। नेपाली स्रोत-भाषा सूची स्थिर गरियो र क्यानोनिकल अनुक्रम `canonicalIndex` बाट मात्र निर्धारण हुने नियम राखियो। Appendix A बाट स्थानीय मानक oracle, मनपरी शुद्धताको पूर्णाङ्क गणना, स्थानीय परीक्षण सामग्री र तटस्थ context/dispatcher/validation/error/metrics आधार तयार गरियो।

### अवस्था स्वामित्व
उत्पादन स्रोतमा साझा परिवर्तनशील semantic अवस्था छैन। संयोजकीय memo map invocation-स्थानीय अपरिवर्तनीय value हुन्; calendar gate book प्रत्येक invocation मा अपरिवर्तनीय प्रारम्भिक value बाट छुट्टै बनाइन्छ; monster context प्रत्येक call मा नयाँ value हो। `Ref`, परियोजना-स्तरको FFI र उत्पादन `Effect` भेटिएन। परीक्षण runner को `Effect` केवल console output र स्पष्ट failure reporting मा सीमित छ।

### के जानाजानी थपिएको छैन
कुनै legacy bug, scar, compatibility detour वा भविष्यको Patch 01–26 को उत्पादन code थपिएको छैन। Stage 2 सुरु गरिएको छैन।

### बाँकी प्रमाण
वास्तविक PureScript build/test execution मात्र बाँकी छ। उपलब्ध वातावरणमा `purs` र `spago` छैनन् र toolchain स्थापना प्रयास पूरा हुन सकेन।
