declare module 'pg' {
  export interface PoolConfig {
    connectionString?: string;
    connectionTimeoutMillis?: number;
    idleTimeoutMillis?: number;
  }

  export interface QueryResult<T extends object = Record<string, unknown>> {
    rows: T[];
    rowCount: number;
  }

  export class Pool {
    constructor(config?: PoolConfig);

    query<T extends object = Record<string, unknown>>(
      text: string,
      values?: readonly unknown[],
    ): Promise<QueryResult<T>>;

    end(): Promise<void>;
  }
}
