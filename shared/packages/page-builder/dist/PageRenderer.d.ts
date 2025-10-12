/**
 * PageRenderer - Renders pages from database
 * Used in web-frontend for dynamic routing
 */
interface PageRendererProps {
    pageSlug: string;
    context: 'admin' | 'tenant' | 'public';
    tenantId?: string;
}
export declare function PageRenderer({ pageSlug, context, tenantId }: PageRendererProps): import("react/jsx-runtime").JSX.Element;
export default PageRenderer;
//# sourceMappingURL=PageRenderer.d.ts.map