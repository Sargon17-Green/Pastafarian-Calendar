# Stage 1 semantic अवस्था स्वामित्व परीक्षण

यो परीक्षण Stage 1 को स्रोतमा invocation बीच साझा हुने परिवर्तनशील semantic अवस्था छ कि छैन भन्ने विषयमा केन्द्रित छ। निष्कर्ष: semantic अवस्था invocation बीच साझा हुँदैन।

## उत्पादन स्रोत

`Pastafari.BigInteger` पूर्ण रूपमा शुद्ध र अपरिवर्तनीय value मा आधारित छ। कुनै `Effect`, `Ref`, FFI वा साझा परिवर्तनशील cell छैन। प्रत्येक गणनाले नयाँ `Big` value फर्काउँछ।

`Pastafari.SourceLanguageCatalog` मा दुई स्थिर अपरिवर्तनीय array छन्। तिनका string लाई rank, unrank वा semantic cache key का रूपमा प्रयोग गरिँदैन। semantic code ले `canonicalIndex` प्रयोग गर्छ र string प्रस्तुति तहमा मात्र समाधान हुन्छ।

`Pastafari.Normative.Reference` शुद्ध छ। `buildStones` module तहको अपरिवर्तनीय value हो; initialization पछि बदलिने अवस्था होइन। counts, hidden drops, visible drops, bowls र order सबै function भित्रका अपरिवर्तनीय value हुन्।

`Pastafari.Normative.Combinatorics` का memo map प्रत्येक count वा unrank invocation भित्र `Map.empty` बाट सुरु हुन्छन् र recursion मार्फत value का रूपमा अगाडि सारिन्छन्। तिनीहरू साझा cache होइनन्, परिवर्तनशील reference होइनन्, र अर्को invocation ले अघिल्लो memo देख्न सक्दैन।

`Pastafari.Normative.Calendar` को `initialGateBook` अपरिवर्तनीय प्रारम्भिक value हो। gate विस्तारले पुरानो book बदल्दैन; नयाँ `Map` सहित नयाँ record फर्काउँछ। `calendarDateCanonical` प्रत्येक invocation मा यही प्रारम्भिक value बाट छुट्टै gate book बनाउँछ। त्यसैले अघिल्लो gate खोजको इतिहास अर्को invocation मा चुहिँदैन।

`Pastafari.Monster.Base` को `MonsterContext` प्रत्येक `bootstrapMonster` call मा `initialContext` बाट नयाँ अपरिवर्तनीय record का रूपमा बनाइन्छ। dispatcher र metric shell ले record update मार्फत नयाँ value फर्काउँछन्। Stage 1 मा साझा registry, `Ref` वा परिवर्तनशील singleton छैन।

## `Effect` र परीक्षण runner

उत्पादन `src/` मा `Effect` import छैन। `Effect` केवल `test/Main.purs` मा परीक्षण नतिजा console मा देखाउन र असफल suite मा स्पष्ट error फाल्न प्रयोग हुन्छ। अपेक्षित वा actual semantic value `Effect` अवस्थाबाट पढिँदैन। `Ref` प्रयोग छैन र परीक्षणको क्रमले oracle को semantic अवस्था बदल्न सक्दैन।

## FFI र initialization

परियोजनाको स्रोतमा `foreign import`, `unsafePerformEffect`, परिवर्तनशील FFI bridge वा बाह्य BigInt binding छैन। module initialization मा परिवर्तनशील semantic अवस्था बनाइँदैन। साझा देखिने `buildStones`, क्याटलग array र `initialGateBook` अपरिवर्तनीय PureScript value मात्र हुन्।

## प्रत्यक्ष जाँच

स्रोत scan मा उत्पादन `Effect` import 0, `Ref` 0, `foreign import` 0, `unsafePerformEffect` 0 र परिवर्तनशील/ST token 0 भेटिए। परीक्षण पक्षमा `Effect` import भएको एउटै file `test/Main.purs` हो।

## निष्कर्ष

Stage 1 का semantic owner स्पष्ट छन्: sauce, DP, gate र monster का intermediate value invocation-स्थानीय छन्; क्याटलग र stone table साझा भए पनि अपरिवर्तनीय छन्; अवलोकन side effect परीक्षण runner को console output मा सीमित छ। त्यसैले `SEMANTIC_STATE_OWNER_VALIDATED=YES` सही छ।
