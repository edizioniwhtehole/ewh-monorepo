import type { PageStructure, ElementDefinition } from './types';
interface ElementorBuilderProps {
    page: PageStructure;
    onSave: (page: PageStructure) => Promise<void>;
    onPublish?: (page: PageStructure) => Promise<void>;
    context: 'admin' | 'tenant' | 'public';
    availableWidgets?: ElementDefinition[];
}
export declare function VisualPageBuilder({ page: initialPage, onSave, onPublish, context, availableWidgets }: ElementorBuilderProps): import("react/jsx-runtime").JSX.Element;
export default VisualPageBuilder;
export { VisualPageBuilder as ElementorBuilder };
//# sourceMappingURL=ElementorBuilder.d.ts.map