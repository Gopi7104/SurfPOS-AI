import { describe, it, expect, vi } from 'vitest';
import { createToolRegistry } from '../../../../src/modules/ai/tools/index.js';

describe('tools/index (registry dispatch)', () => {
  it('dispatches to the matched tool/function with (uid, params)', async () => {
    const inventoryTool = { search: vi.fn().mockResolvedValue({ available: true, message: 'ok' }) };
    const registry = createToolRegistry({ inventoryTool });

    const result = await registry.executeTool(
      { tool: 'inventory', function: 'search', params: { query: 'wax' } },
      'uid-1',
    );

    expect(inventoryTool.search).toHaveBeenCalledWith('uid-1', { query: 'wax' });
    expect(result).toEqual({ available: true, message: 'ok' });
  });

  it('throws for a tool category that does not exist', async () => {
    const registry = createToolRegistry();
    await expect(registry.executeTool({ tool: 'nope', function: 'x', params: {} }, 'uid-1')).rejects.toThrow(
      /Unknown AI tool/,
    );
  });

  it.each(['billing', 'dashboard', 'reports', 'customer'])(
    '%s is intentionally not registered (Phase AI-3 routes it to the client instead)',
    async (tool) => {
      const registry = createToolRegistry();
      await expect(registry.executeTool({ tool, function: 'anything', params: {} }, 'uid-1')).rejects.toThrow(
        /Unknown AI tool/,
      );
    },
  );

  it('throws for a function that does not exist on a known tool', async () => {
    const inventoryTool = { search: vi.fn() };
    const registry = createToolRegistry({ inventoryTool });
    await expect(
      registry.executeTool({ tool: 'inventory', function: 'doesNotExist', params: {} }, 'uid-1'),
    ).rejects.toThrow(/Unknown AI tool/);
  });
});
