export function paramCase(input: string): string {
    if (!input) return '';
    return input
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, ' ')
        .trim()
        .replace(/\s+/g, '-')
        .replace(/^-+|-+$/g, '');
}
