/**
 * PageRenderer - Renders pages from database
 * Used in web-frontend for dynamic routing
 */
'use client';
import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useState, useEffect } from 'react';
export function PageRenderer({ pageSlug, context, tenantId }) {
    const [page, setPage] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    useEffect(() => {
        fetchPage();
    }, [pageSlug, context, tenantId]);
    async function fetchPage() {
        setLoading(true);
        setError(null);
        try {
            const params = new URLSearchParams({
                slug: pageSlug,
                context,
                ...(tenantId && { tenantId })
            });
            const response = await fetch(`/api/pages/render?${params}`);
            if (!response.ok) {
                throw new Error('Page not found');
            }
            const data = await response.json();
            setPage(data);
        }
        catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to load page');
        }
        finally {
            setLoading(false);
        }
    }
    if (loading) {
        return (_jsx("div", { className: "flex items-center justify-center min-h-screen", children: _jsx("div", { className: "animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" }) }));
    }
    if (error || !page) {
        return (_jsx("div", { className: "flex items-center justify-center min-h-screen", children: _jsxs("div", { className: "text-center", children: [_jsx("h1", { className: "text-4xl font-bold text-neutral-900 mb-4", children: "404" }), _jsx("p", { className: "text-neutral-600", children: error || 'Page not found' })] }) }));
    }
    return (_jsx("div", { className: "page-renderer", style: page.settings.layout === 'boxed' ? { maxWidth: page.settings.maxWidth || '1200px', margin: '0 auto' } : undefined, children: page.elements.map((element) => renderElement(element)) }));
}
function renderElement(element) {
    const style = element.styles || {};
    switch (element.type) {
        case 'section':
            return (_jsx("section", { style: style, children: _jsx("div", { className: "container mx-auto", children: _jsx("div", { className: "flex flex-wrap -mx-4", children: element.children?.map((child) => renderElement(child)) }) }) }, element.id));
        case 'column':
            return (_jsx("div", { className: "px-4", style: style, children: element.children?.map((child) => renderElement(child)) }, element.id));
        case 'heading':
            const HeadingTag = (element.props.tag || 'h2');
            return (_jsx(HeadingTag, { style: style, children: element.props.text }, element.id));
        case 'text':
            return (_jsx("div", { style: style, dangerouslySetInnerHTML: { __html: element.props.content } }, element.id));
        case 'button':
            return (_jsx("a", { href: element.props.link, style: style, children: element.props.text }, element.id));
        case 'image':
            return (_jsx("img", { src: element.props.src, alt: element.props.alt, style: style }, element.id));
        case 'spacer':
            return _jsx("div", { style: style }, element.id);
        case 'divider':
            return _jsx("hr", { style: style }, element.id);
        case 'video':
            return (_jsx("video", { controls: true, style: style, children: _jsx("source", { src: element.props.src }) }, element.id));
        case 'widget':
            // Load widget dynamically
            return (_jsxs("div", { className: "widget-container", children: ["Widget: ", element.props.widgetId] }, element.id));
        default:
            return null;
    }
}
export default PageRenderer;
//# sourceMappingURL=PageRenderer.js.map