using System.Numerics;
namespace PastafarianCalendar.Monster;

// تنفيذ اثنتي عشرة دورة من التحريك اللاحق بقيم قديمة ثابتة لكل دورة.
public sealed record LegacyPostStirSnapshot(int Ordinal,BigInteger SavedBowlSum,int[] Order,BigInteger[] Bowls);

public sealed class LegacyPostStirRound
{
    private readonly SavePatchWrapper _save=new();
    private readonly BowlOrderPatchWrapper _unrank=new();

    public LegacyPostStirSnapshot Stir(BigInteger[] bowls,int ordinal)
    {
        if(ordinal is < 1 or > 12 || bowls is null || bowls.Length!=7 ||
           bowls[0]!=BigInteger.Zero || bowls.Skip(1).Any(x=>x<1))
            throw new MonsterValidationException("التحريك اللاحق يحتاج ستة أوعية ورقم دورة صحيحاً.");

        var old=(BigInteger[])bowls.Clone();
        var raw=old[1]+old[2]+old[3]+old[4]+old[5]+old[6];
        var saved=_save.SavePatch(raw+149*ordinal);
        var order=_unrank.OrderPatchFromValue(saved).Order;
        var pending=(BigInteger[])old.Clone();
        for(var pos=1;pos<=6;pos++)
        {
            var id=order[pos-1];
            var prev=order[(pos+4)%6];
            var next=order[pos%6];
            var z=old[id]+3*old[prev]+5*old[next]+saved+ordinal+pos*pos;
            pending[id]=_save.SavePatch(z*z+7*old[prev]*old[next]);
        }
        for(var id=1;id<=6;id++)bowls[id]=pending[id];
        return new LegacyPostStirSnapshot(ordinal,saved,order,(BigInteger[])bowls.Clone());
    }
}
