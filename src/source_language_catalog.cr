module PastafarianCalendar
  module SourceLanguageCatalog
    VERSION = "1.0.0"
    LANGUAGE = "ગુજરાતી"
    FROZEN = true

    record Entry, canonical_index : Int32, text : String

    CUTLETS = {
      Entry.new(1, "કાંસું"),
      Entry.new(2, "શિયાળ"),
      Entry.new(3, "વૃક્ક"),
      Entry.new(4, "લગાશ"),
      Entry.new(5, "વિચાર"),
      Entry.new(6, "નવમાંથી ચાર ભાગ"),
      Entry.new(7, "ફલ્ગુરશ"),
      Entry.new(8, "પેપિરસ"),
      Entry.new(9, "ગુચ્છ"),
      Entry.new(10, "વીંછી"),
      Entry.new(11, "રાખ"),
      Entry.new(12, "ઘઉં"),
      Entry.new(13, "નદી"),
      Entry.new(14, "હાસ્ય"),
      Entry.new(15, "અક્કદ"),
      Entry.new(16, "શિંગડું"),
      Entry.new(17, "ખાલી ઘડો"),
    }

    MONTHS = {
      Entry.new(1, "ચીકણી માટી"),
      Entry.new(2, "દાડમ"),
      Entry.new(3, "કોણી"),
      Entry.new(4, "ઈર્ષ્યા"),
      Entry.new(5, "એરિડુ"),
      Entry.new(6, "દાંતમંજન"),
      Entry.new(7, "પાંચમાંથી ત્રણ ભાગ"),
      Entry.new(8, "કર્શુમવ"),
      Entry.new(9, "દીપડો"),
      Entry.new(10, "કલાઈ"),
      Entry.new(11, "ધુમ્મસ"),
      Entry.new(12, "લોબાન"),
      Entry.new(13, "તકલી"),
      Entry.new(14, "પાંસળી"),
      Entry.new(15, "કેરોબ"),
      Entry.new(16, "ઉરુક"),
      Entry.new(17, "શરમ"),
      Entry.new(18, "ઊંટ"),
      Entry.new(19, "તાંબું"),
      Entry.new(20, "કૂવો"),
      Entry.new(21, "જરદી"),
      Entry.new(22, "તારો"),
      Entry.new(23, "મધ"),
      Entry.new(24, "બરોળ"),
      Entry.new(25, "ચૂનાપથ્થર"),
      Entry.new(26, "આનંદ"),
      Entry.new(27, "અંજીર"),
      Entry.new(28, "નિનેવે"),
      Entry.new(29, "દેડકો"),
      Entry.new(30, "ડામર"),
      Entry.new(31, "મીણબત્તી"),
      Entry.new(32, "બંધ દરવાજો"),
      Entry.new(33, "તલ"),
      Entry.new(34, "ગરદનનો પાછળનો ભાગ"),
      Entry.new(35, "ચાંદી"),
      Entry.new(36, "લિલી"),
      Entry.new(37, "તોફાન"),
      Entry.new(38, "ગધેડો"),
      Entry.new(39, "લોટ"),
      Entry.new(40, "પસ્તાવો"),
      Entry.new(41, "બાબેલ"),
      Entry.new(42, "જીભ"),
      Entry.new(43, "અળસી"),
      Entry.new(44, "મીઠું"),
      Entry.new(45, "નાશપતી"),
      Entry.new(46, "ધનુષ્ય"),
      Entry.new(47, "રેતી"),
    }

    def self.cutlet(index : Int32) : String
      raise IndexError.new("E_CUTLET_INDEX") unless 1 <= index <= CUTLETS.size
      CUTLETS[index - 1].text
    end

    def self.month(index : Int32) : String
      raise IndexError.new("E_MONTH_INDEX") unless 1 <= index <= MONTHS.size
      MONTHS[index - 1].text
    end
  end
end
