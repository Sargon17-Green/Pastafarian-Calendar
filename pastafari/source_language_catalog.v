module pastafari

pub const source_language_catalog_version = '1.3.1'

pub enum NameKind {
	cutlet
	month
}

pub struct CanonicalName {
pub:
	kind            NameKind
	canonical_index int
	text            string
}

fn cutlet_source_names() []string {
	return [
		'ነሐስ',
		'ቀበሮ',
		'ኩላሊት',
		'ላጋሽ',
		'ሐሳብ',
		'ከዘጠኝ አራት ክፍሎች',
		'ፓልጉራሽ',
		'የረግረግ ሣር',
		'ዘለላ',
		'ጊንጥ',
		'አመድ',
		'ስንዴ',
		'ወንዝ',
		'ሳቅ',
		'አካድ',
		'ቀንድ',
		'ባዶ ማሰሮ',
	]
}

fn month_source_names() []string {
	return [
		'ጭቃ',
		'ሮማን',
		'ክርን',
		'ቅናት',
		'ኤሪዱ',
		'የጥርስ ሳሙና',
		'ከአምስት ሦስት ክፍሎች',
		'ካርሹማብ',
		'ነብር',
		'ቆርቆሮ',
		'ጭጋግ',
		'ዕጣን',
		'እንዝርት',
		'የጎን አጥንት',
		'የካሮብ ፍሬ',
		'ኡሩክ',
		'ኀፍረት',
		'ግመል',
		'መዳብ',
		'የውሃ ጉድጓድ',
		'የእንቁላል አስኳል',
		'ኮከብ',
		'ማር',
		'ጣፊያ',
		'የኖራ ድንጋይ',
		'ደስታ',
		'በለስ',
		'ነነዌ',
		'እንቁራሪት',
		'ሬንጅ',
		'ሻማ',
		'የተዘጋው በር',
		'ሰሊጥ',
		'የአንገት ኋላ',
		'ብር',
		'ሊሊ አበባ',
		'ማዕበል',
		'አህያ',
		'ዱቄት',
		'ጸጸት',
		'ባቢሎን',
		'ምላስ',
		'ተልባ',
		'ጨው',
		'ፒር ፍሬ',
		'ቀስት',
		'አሸዋ',
	]
}

pub fn source_language_catalog() []CanonicalName {
	cutlets := cutlet_source_names()
	months := month_source_names()
	mut out := []CanonicalName{cap: cutlets.len + months.len}
	for i, text in cutlets {
		out << CanonicalName{
			kind:            .cutlet
			canonical_index: i + 1
			text:            text
		}
	}
	for i, text in months {
		out << CanonicalName{
			kind:            .month
			canonical_index: i + 1
			text:            text
		}
	}
	return out
}

pub fn cutlet_name_by_index(index int) !string {
	names := cutlet_source_names()
	if index < 1 || index > names.len {
		return error('የቆራጭ ስም መለያው ከተፈቀደው ወሰን ውጭ ነው')
	}
	return names[index - 1]
}

pub fn month_name_by_index(index int) !string {
	names := month_source_names()
	if index < 1 || index > names.len {
		return error('የወር ስም መለያው ከተፈቀደው ወሰን ውጭ ነው')
	}
	return names[index - 1]
}
