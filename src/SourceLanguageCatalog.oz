functor
export
   Version
   CutletEntries
   MonthEntries
   CutletName
   MonthName
   CutletCount
   MonthCount
   ValidateCatalog

define
   % Ovaj je katalog jedini hrvatski izvorni sloj naziva.
   % Semantika se oslanja samo na canonicalIndex; tekst se razrješava tek pri prikazu.
   Version = '1.0.0'

   CutletEntries = [
      entry(canonicalIndex:1  text:"bronca")
      entry(canonicalIndex:2  text:"lisica")
      entry(canonicalIndex:3  text:"bubreg")
      entry(canonicalIndex:4  text:"Lagaš")
      entry(canonicalIndex:5  text:"misao")
      entry(canonicalIndex:6  text:"četiri devetine")
      entry(canonicalIndex:7  text:"Palguraš")
      entry(canonicalIndex:8  text:"papirus")
      entry(canonicalIndex:9  text:"grozd")
      entry(canonicalIndex:10 text:"škorpion")
      entry(canonicalIndex:11 text:"pepeo")
      entry(canonicalIndex:12 text:"pšenica")
      entry(canonicalIndex:13 text:"rijeka")
      entry(canonicalIndex:14 text:"smijeh")
      entry(canonicalIndex:15 text:"Akad")
      entry(canonicalIndex:16 text:"rog")
      entry(canonicalIndex:17 text:"prazni vrč")
   ]

   MonthEntries = [
      entry(canonicalIndex:1  text:"glina")
      entry(canonicalIndex:2  text:"nar")
      entry(canonicalIndex:3  text:"lakat")
      entry(canonicalIndex:4  text:"zavist")
      entry(canonicalIndex:5  text:"Eridu")
      entry(canonicalIndex:6  text:"pasta za zube")
      entry(canonicalIndex:7  text:"tri petine")
      entry(canonicalIndex:8  text:"Karšumav")
      entry(canonicalIndex:9  text:"leopard")
      entry(canonicalIndex:10 text:"kositar")
      entry(canonicalIndex:11 text:"magla")
      entry(canonicalIndex:12 text:"tamjan")
      entry(canonicalIndex:13 text:"vreteno")
      entry(canonicalIndex:14 text:"rebro")
      entry(canonicalIndex:15 text:"rogač")
      entry(canonicalIndex:16 text:"Uruk")
      entry(canonicalIndex:17 text:"sram")
      entry(canonicalIndex:18 text:"deva")
      entry(canonicalIndex:19 text:"bakar")
      entry(canonicalIndex:20 text:"bunar")
      entry(canonicalIndex:21 text:"žumanjak")
      entry(canonicalIndex:22 text:"zvijezda")
      entry(canonicalIndex:23 text:"med")
      entry(canonicalIndex:24 text:"slezena")
      entry(canonicalIndex:25 text:"vapnenac")
      entry(canonicalIndex:26 text:"radost")
      entry(canonicalIndex:27 text:"smokva")
      entry(canonicalIndex:28 text:"Niniva")
      entry(canonicalIndex:29 text:"žaba")
      entry(canonicalIndex:30 text:"katran")
      entry(canonicalIndex:31 text:"svijeća")
      entry(canonicalIndex:32 text:"zatvorena vrata")
      entry(canonicalIndex:33 text:"sezam")
      entry(canonicalIndex:34 text:"zatiljak")
      entry(canonicalIndex:35 text:"srebro")
      entry(canonicalIndex:36 text:"ljiljan")
      entry(canonicalIndex:37 text:"oluja")
      entry(canonicalIndex:38 text:"magarac")
      entry(canonicalIndex:39 text:"brašno")
      entry(canonicalIndex:40 text:"kajanje")
      entry(canonicalIndex:41 text:"Babilon")
      entry(canonicalIndex:42 text:"jezik")
      entry(canonicalIndex:43 text:"lan")
      entry(canonicalIndex:44 text:"sol")
      entry(canonicalIndex:45 text:"kruška")
      entry(canonicalIndex:46 text:"luk")
      entry(canonicalIndex:47 text:"pijesak")
   ]

   CutletCount = 17
   MonthCount = 47

   fun {EntryName Entries Index}
      if Index < 1 orelse Index > {List.length Entries} then
         raise catalogIndexOutOfRange(index:Index) end
      else
         {List.nth Entries Index}.text
      end
   end

   fun {CutletName Index}
      {EntryName CutletEntries Index}
   end

   fun {MonthName Index}
      {EntryName MonthEntries Index}
   end

   fun {IndicesAreConsecutive Entries Expected}
      fun {Loop Xs I}
         case Xs
         of nil then I == Expected + 1
         [] X|Xr then
            X.canonicalIndex == I andthen {Loop Xr I+1}
         end
      end
   in
      {Loop Entries 1}
   end

   fun {ValidateCatalog}
      {List.length CutletEntries} == CutletCount
      andthen {List.length MonthEntries} == MonthCount
      andthen {IndicesAreConsecutive CutletEntries CutletCount}
      andthen {IndicesAreConsecutive MonthEntries MonthCount}
   end
end
