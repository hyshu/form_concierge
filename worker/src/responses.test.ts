import assert from 'node:assert/strict';
import test from 'node:test';

import { answerRow, questionRow } from '../test/fixtures';
import { csvCell, formatAnswerForCsv, incrementChoiceCount, utcMidnight } from './responses';

test('utcMidnight floors to UTC calendar day start', () => {
  const afternoon = new Date('2026-07-10T15:30:45.123Z');
  assert.equal(utcMidnight(afternoon).toISOString(), '2026-07-10T00:00:00.000Z');
  const alreadyMidnight = new Date('2026-07-10T00:00:00.000Z');
  assert.equal(utcMidnight(alreadyMidnight).toISOString(), '2026-07-10T00:00:00.000Z');
});

test('incrementChoiceCount ignores unknown choice ids', () => {
  const counts = { '1': 0 };
  incrementChoiceCount(counts, 1);
  assert.deepEqual(counts, { '1': 1 });

  // Orphaned ids (choice deleted after answer) must not throw.
  incrementChoiceCount(counts, 2);
  assert.deepEqual(counts, { '1': 1 });
});

test('formatAnswerForCsv labels missing choice text instead of throwing', () => {
  assert.equal(
    formatAnswerForCsv(
      questionRow({ id: 10, type: 'multipleChoice' }),
      answerRow({ question_id: 10, selected_choice_ids: '[1]' }),
      new Map([[1, 'Yes']]),
    ),
    'Yes',
  );

  assert.equal(
    formatAnswerForCsv(
      questionRow({ id: 10, type: 'multipleChoice' }),
      answerRow({ question_id: 10, selected_choice_ids: '[2]' }),
      new Map([[1, 'Yes']]),
    ),
    '[deleted choice 2]',
  );
});

test('csvCell neutralizes formula injection prefixes', () => {
  assert.equal(csvCell('=1+1'), "'=1+1");
  assert.equal(csvCell('+cmd'), "'+cmd");
  assert.equal(csvCell('-1'), "'-1");
  assert.equal(csvCell('@SUM(A1)'), "'@SUM(A1)");
  assert.equal(csvCell('plain'), 'plain');
  assert.equal(csvCell('say "hi"'), '"say ""hi"""');
});

test('isUniqueConstraintError ignores generic FK constraint failures', async () => {
  const { isUniqueConstraintError } = await import('./utils');
  assert.equal(
    isUniqueConstraintError(new Error('UNIQUE constraint failed: admins.email')),
    true,
  );
  assert.equal(
    isUniqueConstraintError(new Error('FOREIGN KEY constraint failed')),
    false,
  );
  assert.equal(
    isUniqueConstraintError(new Error('SQLITE_CONSTRAINT_UNIQUE')),
    true,
  );
});
