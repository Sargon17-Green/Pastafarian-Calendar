with Ada.Strings.Wide_Wide_Unbounded;

package Source_Language_Catalog is
   pragma Elaborate_Body;

   subtype Cutlet_Canonical_Index is Positive range 1 .. 17;
   subtype Month_Canonical_Index  is Positive range 1 .. 47;

   function Cutlet_Name
     (Index : Cutlet_Canonical_Index)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Month_Name
     (Index : Month_Canonical_Index)
      return Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;

   function Cutlet_Count return Positive is (17);
   function Month_Count  return Positive is (47);

   function Catalog_Version return String is ("1.0.0-stage01-frozen");
end Source_Language_Catalog;
