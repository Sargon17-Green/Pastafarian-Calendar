'use strict';

(function (root) {
  function frozenMessages(messages) {
    return Object.freeze(messages);
  }

  const locales = Object.freeze([
    Object.freeze({
      code: 'ie',
      displayName: 'Interlingue',
      dir: 'ltr',
      intlLocale: 'ie',
      messages: frozenMessages({
        'app.title': 'Calendare Pastafarian',
        'language.label': 'Lingue',
        'loading.kicker': 'Calculat localmen',
        'loading.title': 'Trovante li cutlet e li date…',
        'error.kicker': 'Ne posse monstrar li calendare',
        'error.reload': 'Recargar',
        'error.timeout': 'Li calcul dura tro long.',
        'error.engineFailed': 'Li motor de calcul fallit.',
        'error.engineLoadFailed': 'Li motor de calcul ne posset esser cargat.',
        'calendar.toolbarAria': 'Navigation inter cutlets',
        'calendar.previous': 'Precedent cutlet',
        'calendar.next': 'Sequent cutlet',
        'calendar.daysAria': 'Dies in li cutlet {cutletName}',
        'calendar.currentCutlet': 'Annu {year} · cutlet',
        'calendar.cutletDescription': '{count} dies · die de labor: {actionDate}',
        'search.kicker': 'Sercha de date',
        'search.heading': 'Quel die vu vole trovar?',
        'search.submit': 'Monstrar li date',
        'search.invalid': 'Ti date ne posset esser reconosset. Controla que omni campes es complet e que li date existe.',
        'settings.summary': 'Optiones de calcul e comparation',
        'settings.heading': 'Changear li die de labor',
        'settings.invalid': 'Li die de labor es invalid. Controla li date e prova denov.',
        'reverse.action.cancel': 'Anullar',
        'field.day': 'Die',
        'date.aria': 'Annu {year} desde li Creation del Munde, die {dayInCutlet} in li cutlet {cutletName}, die {dayInMonth} in li mensu {monthName}',
        'date.cutletLine': 'Die {dayInCutlet} in li cutlet {cutletName}',
        'date.monthLine': 'Die {dayInMonth} in li mensu {monthName}',
      }),
    }),
    Object.freeze({
      code: 'en',
      displayName: 'English',
      dir: 'ltr',
      intlLocale: 'en-US',
      messages: frozenMessages({
        'app.title': 'Pastafari Calendar',
        'language.label': 'Language',
        'loading.kicker': 'Calculated locally',
        'loading.title': 'Finding the cutlet and date…',
        'error.kicker': 'Unable to display the calendar',
        'error.reload': 'Reload',
        'error.timeout': 'The calculation is taking too long.',
        'error.engineFailed': 'The calculation engine failed.',
        'error.engineLoadFailed': 'The calculation engine could not be loaded.',
        'calendar.toolbarAria': 'Cutlet navigation',
        'calendar.previous': 'Previous cutlet',
        'calendar.next': 'Next cutlet',
        'calendar.daysAria': 'Days in the cutlet {cutletName}',
        'calendar.currentCutlet': 'Year {year} · cutlet',
        'calendar.cutletDescription': '{count} days · day of working: {actionDate}',
        'search.kicker': 'Date search',
        'search.heading': 'Which day would you like to find?',
        'search.submit': 'Show date',
        'search.invalid': 'That date could not be recognized. Check that every field is complete and that the date exists.',
        'settings.summary': 'Calculation and comparison options',
        'settings.heading': 'Change the day of working',
        'settings.invalid': 'The day of working is invalid. Check the date and try again.',
        'reverse.action.cancel': 'Cancel',
        'field.day': 'Day',
        'date.aria': 'Year {year} from the Creation of the World, day {dayInCutlet} in the cutlet {cutletName}, day {dayInMonth} in the month {monthName}',
        'date.cutletLine': 'Day {dayInCutlet} in the cutlet {cutletName}',
        'date.monthLine': 'Day {dayInMonth} in the month {monthName}',
      }),
    }),
  ]);

  root.PastafariBrowserLocaleData = Object.freeze({
    schemaVersion: 1,
    provenance: 'embedded-initial-browser-interface',
    defaultLocale: 'ie',
    locales,
  });
})(typeof globalThis === 'object' ? globalThis : this);
