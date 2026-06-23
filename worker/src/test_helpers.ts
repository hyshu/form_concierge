export function d1Meta(): D1Result<unknown>['meta'] {
  return {
    duration: 0,
    size_after: 0,
    rows_read: 0,
    rows_written: 0,
    last_row_id: 0,
    changed_db: false,
    changes: 0,
  };
}

export function d1Result<T>(results: T[]): D1Result<T> {
  return {
    success: true,
    meta: d1Meta(),
    results,
  };
}

export function emptyD1Result<T>(): D1Result<T> {
  return d1Result<T>([]);
}

export function emptyD1Raw<T = unknown[]>(options: { columnNames: true }): Promise<[string[], ...T[]]>;
export function emptyD1Raw<T = unknown[]>(options?: { columnNames?: false }): Promise<T[]>;
export async function emptyD1Raw(_options?: { columnNames?: boolean }): Promise<unknown[]> {
  return [];
}
