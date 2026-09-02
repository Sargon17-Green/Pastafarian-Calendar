module source_language_catalog
  implicit none
  private

  integer, parameter, public :: CUTLET_NAME_COUNT = 17
  integer, parameter, public :: MONTH_NAME_COUNT = 47
  integer, parameter, public :: SOURCE_LANGUAGE_CATALOG_VERSION = 1

  character(len=32), parameter, public :: CUTLET_NAMES_EN(CUTLET_NAME_COUNT) = [character(len=32) :: &
       'Bronze', &
       'Fox', &
       'Kidney', &
       'Lagash', &
       'Thought', &
       'Four Parts of Nine', &
       'Palgurash', &
       'Papyrus Sedge', &
       'Cluster', &
       'Scorpion', &
       'Ash', &
       'Wheat', &
       'River', &
       'Laughter', &
       'Akkad', &
       'Horn', &
       'The Empty Jar' ]

  character(len=32), parameter, public :: MONTH_NAMES_EN(MONTH_NAME_COUNT) = [character(len=32) :: &
       'Clay', &
       'Pomegranate', &
       'Elbow', &
       'Envy', &
       'Eridu', &
       'Toothpaste', &
       'Three Parts of Five', &
       'Karshumav', &
       'Tiger', &
       'Tin', &
       'Fog', &
       'Frankincense', &
       'Spindle', &
       'Rib', &
       'Carob', &
       'Uruk', &
       'Shame', &
       'Camel', &
       'Copper', &
       'Well', &
       'Yolk', &
       'Star', &
       'Honey', &
       'Spleen', &
       'Limestone', &
       'Joy', &
       'Fig', &
       'Nineveh', &
       'Frog', &
       'Tar', &
       'Candle', &
       'The Closed Door', &
       'Sesame', &
       'Nape', &
       'Silver', &
       'Lily', &
       'Storm', &
       'Donkey', &
       'Flour', &
       'Regret', &
       'Babylon', &
       'Tongue', &
       'Flax', &
       'Salt', &
       'Pear', &
       'Bow', &
       'Sand' ]

  public :: cutlet_name_from_index, month_name_from_index

contains

  function cutlet_name_from_index(canonicalIndex) result(name)
    integer, intent(in) :: canonicalIndex
    character(len=:), allocatable :: name
    if (canonicalIndex < 1 .or. canonicalIndex > CUTLET_NAME_COUNT) error stop 'invalid cutlet canonical index'
    name = trim(CUTLET_NAMES_EN(canonicalIndex))
  end function cutlet_name_from_index

  function month_name_from_index(canonicalIndex) result(name)
    integer, intent(in) :: canonicalIndex
    character(len=:), allocatable :: name
    if (canonicalIndex < 1 .or. canonicalIndex > MONTH_NAME_COUNT) error stop 'invalid month canonical index'
    name = trim(MONTH_NAMES_EN(canonicalIndex))
  end function month_name_from_index

end module source_language_catalog
