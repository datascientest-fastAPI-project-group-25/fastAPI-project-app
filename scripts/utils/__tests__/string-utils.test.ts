import { describe, test, expect } from 'vitest';
import { paramCase } from '../index';

describe('paramCase', () => {
    test('converts a string to param case', () => {
        expect(paramCase('Hello World')).toBe('hello-world');
    });

    test('handles empty string', () => {
        expect(paramCase('')).toBe('');
    });

    test('handles null or undefined', () => {
        expect(paramCase(null as unknown as string)).toBe('');
        expect(paramCase(undefined as unknown as string)).toBe('');
    });

    test('removes special characters', () => {
        expect(paramCase('Hello, World!')).toBe('hello-world');
    });

    test('converts to lowercase', () => {
        expect(paramCase('HELLO WORLD')).toBe('hello-world');
    });

    test('replaces multiple spaces with a single dash', () => {
        expect(paramCase('Hello   World')).toBe('hello-world');
    });

    test('trims leading and trailing dashes', () => {
        expect(paramCase('  Hello World  ')).toBe('hello-world');
        expect(paramCase('-Hello World-')).toBe('hello-world');
    });
});
