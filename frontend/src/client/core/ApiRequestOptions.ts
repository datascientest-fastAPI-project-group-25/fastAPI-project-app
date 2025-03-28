export type ApiRequestOptions<T = unknown> = {
  readonly body?: T;
  readonly cookies?: Record<string, unknown>;
  readonly errors?: Record<number | string, string>;
  readonly formData?: Record<string, unknown> | T[] | Blob | File;
  readonly headers?: Record<string, unknown>;
  readonly mediaType?: string;
  readonly method:
    | "DELETE"
    | "GET"
    | "HEAD"
    | "OPTIONS"
    | "PATCH"
    | "POST"
    | "PUT";
  readonly path?: Record<string, unknown>;
  readonly query?: Record<string, unknown>;
  readonly responseHeader?: string;
  readonly responseTransformer?: (data: unknown) => Promise<T>;
  readonly url: string;
};
