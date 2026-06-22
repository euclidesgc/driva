import { InMemoryWidgetRepository } from "./in-memory";
import type { WidgetRepository } from "./types";

export type { SaveInput, WidgetRepository } from "./types";
export { InMemoryWidgetRepository } from "./in-memory";

/**
 * Instância default consumida pela UI. Para conectar o backend no M3, troque
 * esta linha por `new ApiWidgetRepository(...)` — nada na UI muda.
 */
export const widgetRepository: WidgetRepository = new InMemoryWidgetRepository();
