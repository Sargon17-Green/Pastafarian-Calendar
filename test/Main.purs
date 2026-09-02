module Test.Main where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console as Console
import Effect.Exception (error, throw)
import Pastafari.BigInteger as B
import Pastafari.Monster (bootstrapMonster)
import Pastafari.Monster.Base (MonsterStatus(..))
import Pastafari.Normative.Reference as R
import Pastafari.SourceLanguageCatalog as Catalog

assertTrue :: String -> Boolean -> Effect Unit
assertTrue label condition =
  if condition then Console.log ("ठीक: " <> label)
  else throw (error ("असफल: " <> label))

main :: Effect Unit
main = do
  let m = R.modulusM
  assertTrue "SAVE(M) = M" (R.save m == m)
  assertTrue "SAVE(2M) = M" (R.save (B.mul (B.fromInt 2) m) == m)
  assertTrue "SAVE(M+1) = 1" (R.save (B.add m B.one) == B.one)
  assertTrue "Foundation को dayCount 1 हुन्छ" (R.dayCount R.foundationDay == B.one)
  assertTrue "Foundation पछिको दिन 3 हुन्छ" (R.dayCount (B.add R.foundationDay B.one) == B.fromInt 3)
  assertTrue "Foundation अघिको दिन 2 हुन्छ" (R.dayCount (B.sub R.foundationDay B.one) == B.fromInt 2)

  let counts = R.workCounts R.foundationDay R.foundationDay
  assertTrue "उही दिनको दूरी 1 हुन्छ" (counts.distance == B.one)
  assertTrue "उही दिनको दिशा 2 हुन्छ" (counts.direction == B.fromInt 2)
  assertTrue "Tablets र Foundation को दूरी 14777149 हुन्छ"
    (B.sub R.tabletsDay R.foundationDay == B.fromInt 14777149)

  assertTrue "कचलेट क्याटलगमा 17 नाम छन्" (Array.length Catalog.cutletCatalog == 17)
  assertTrue "महिना क्याटलगमा 47 नाम छन्" (Array.length Catalog.monthCatalog == 47)
  assertTrue "कचलेट canonicalIndex क्रम स्थिर छ"
    (map _.canonicalIndex Catalog.cutletCatalog == Array.range 1 17)
  assertTrue "महिना canonicalIndex क्रम स्थिर छ"
    (map _.canonicalIndex Catalog.monthCatalog == Array.range 1 47)

  assertTrue "ढुङ्गा तालिकामा 46 पङ्क्ति छन्" (Array.length R.buildStones == 46)
  assertTrue "720 ले अन्तिम lexicographic bowl order दिन्छ"
    (R.bowlOrderFromDrop (B.fromInt 720) == [ 6, 5, 4, 3, 2, 1 ])

  case bootstrapMonster R.foundationDay R.foundationDay of
    Left _ -> throw (error "तटस्थ bootstrap dispatcher असफल भयो")
    Right ctx -> do
      assertTrue "bootstrap dispatcher Ready अवस्थामा पुग्छ" (ctx.status == Ready)
      assertTrue "bootstrap trace खाली हुँदैन" (not (Array.null ctx.branchTrace))

  Console.log "Stage 1 bootstrap परीक्षण फाइल समाप्त भयो।"
