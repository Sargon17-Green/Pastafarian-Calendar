Object subclass: #PSTSourceLanguageCatalog
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTSourceLanguageCatalog class methodsFor: 'catalog'!
version
    ^ '1.0.0'
!

cutletNames
    ^ #(
        'کانسی'
        'لومڑی'
        'گردہ'
        'لاگاش'
        'خیال'
        'نو میں سے چار حصے'
        'پلگورش'
        'پیپرس'
        'گچھا'
        'بچھو'
        'راکھ'
        'گندم'
        'دریا'
        'ہنسی'
        'اکد'
        'سینگ'
        'خالی گھڑا'
    )
!

monthNames
    ^ #(
        'چکنی مٹی'
        'انار'
        'کہنی'
        'حسد'
        'اریدو'
        'دانتوں کا پیسٹ'
        'پانچ میں سے تین حصے'
        'کرشومب'
        'تیندوا'
        'ٹین'
        'دھند'
        'لوبان'
        'تکلا'
        'پسلی'
        'خرنوب'
        'اوروک'
        'شرم'
        'اونٹ'
        'تانبا'
        'کنواں'
        'زردی'
        'ستارہ'
        'شہد'
        'تلی'
        'چونا پتھر'
        'خوشی'
        'انجیر'
        'نینوا'
        'مینڈک'
        'تارکول'
        'موم بتی'
        'بند دروازہ'
        'تل'
        'گدی'
        'چاندی'
        'سوسن'
        'طوفان'
        'گدھا'
        'آٹا'
        'پچھتاوا'
        'بابل'
        'زبان'
        'کتان'
        'نمک'
        'ناشپاتی'
        'کمان'
        'ریت'
    )
!

cutletNameAtCanonicalIndex: anInteger
    (anInteger between: 1 and: 17) ifFalse: [ self error: 'کینونیکل کٹلیٹ اشاریہ حد سے باہر ہے' ].
    ^ self cutletNames at: anInteger
!

monthNameAtCanonicalIndex: anInteger
    (anInteger between: 1 and: 47) ifFalse: [ self error: 'کینونیکل مہینہ اشاریہ حد سے باہر ہے' ].
    ^ self monthNames at: anInteger
!

validate
    | cuts months |
    cuts := self cutletNames.
    months := self monthNames.
    cuts size = 17 ifFalse: [ self error: 'کٹلیٹ فہرست میں سترہ نام لازم ہیں' ].
    months size = 47 ifFalse: [ self error: 'مہینوں کی فہرست میں سینتالیس نام لازم ہیں' ].
    cuts asSet size = 17 ifFalse: [ self error: 'کٹلیٹ نام منفرد نہیں ہیں' ].
    months asSet size = 47 ifFalse: [ self error: 'مہینوں کے نام منفرد نہیں ہیں' ].
    ^ true
!
! !
