package catalog

type Entry struct {
	CanonicalIndex int
	Text           string
}

const Version = "kotava-source-catalog-v1"

var cutlets = [...]Entry{
	{1, "iyekot"},
	{2, "bresitol"},
	{3, "welza"},
	{4, "klupa"},
	{5, "trak"},
	{6, "balemoy fuxe lerd"},
	{7, "Palgurac"},
	{8, "edgarda"},
	{9, "zul"},
	{10, "xaliom"},
	{11, "guboy"},
	{12, "dent"},
	{13, "voa"},
	{14, "kipe"},
	{15, "Akad"},
	{16, "nola"},
	{17, "vlardaf abday"},
}

var months = [...]Entry{
	{1, "kuritca"},
	{2, "kuvime"},
	{3, "ladava"},
	{4, "djum"},
	{5, "Eridu"},
	{6, "zom ke talga"},
	{7, "baroy fuxe alub"},
	{8, "Karcumab"},
	{9, "jaktol"},
	{10, "vopel"},
	{11, "sel"},
	{12, "wexu ke drewa"},
	{13, "jepkeda"},
	{14, "krimba"},
	{15, "ruike"},
	{16, "Uruk"},
	{17, "kinokuca"},
	{18, "wegidol"},
	{19, "lut"},
	{20, "lird"},
	{21, "atoxa"},
	{22, "bitej"},
	{23, "kolt"},
	{24, "wiverda"},
	{25, "kalke"},
	{26, "daava"},
	{27, "agzone"},
	{28, "Ninve"},
	{29, "salma"},
	{30, "wixa"},
	{31, "raki"},
	{32, "budenaf tuvel"},
	{33, "foju"},
	{34, "kapray"},
	{35, "dilgava"},
	{36, "tcuma"},
	{37, "zivotc"},
	{38, "astol"},
	{39, "regelta"},
	{40, "batceks"},
	{41, "Bavel"},
	{42, "yoy"},
	{43, "brelt"},
	{44, "eip"},
	{45, "efte"},
	{46, "tra"},
	{47, "bixe"},
}

func CutletEntries() [17]Entry {
	return cutlets
}

func MonthEntries() [47]Entry {
	return months
}

func CutletText(index int) (string, bool) {
	if index < 1 || index > len(cutlets) {
		return "", false
	}
	return cutlets[index-1].Text, true
}

func MonthText(index int) (string, bool) {
	if index < 1 || index > len(months) {
		return "", false
	}
	return months[index-1].Text, true
}
