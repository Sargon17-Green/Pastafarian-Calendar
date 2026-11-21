/** QA-only structural equality for JSON-compatible external reference records.
 * JSON member order is irrelevant; array order, exact scalar types and keys matter.
 */
import { isDeepStrictEqual } from 'node:util';

export function assertJsonSemanticEqual(actual, expected, where) {
  if (!isDeepStrictEqual(actual, expected)) {
    throw Error(where + ': ' + JSON.stringify(actual) + ' != ' + JSON.stringify(expected));
  }
}
