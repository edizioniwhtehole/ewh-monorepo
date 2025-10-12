/**
 * Page Builder Types
 * Elementor-style visual page builder
 */
export interface PageElement {
    id: string;
    type: ElementType;
    props: Record<string, any>;
    children?: PageElement[];
    styles?: ElementStyles;
    responsive?: ResponsiveStyles;
}
export type ElementType = 'section' | 'column' | 'heading' | 'text' | 'image' | 'button' | 'spacer' | 'divider' | 'icon' | 'video' | 'widget' | 'icon-box' | 'star-rating' | 'progress-bar' | 'counter' | 'testimonial' | 'accordion' | 'tabs' | 'toggle' | 'list' | 'form' | 'input' | 'textarea' | 'select' | 'checkbox' | 'submit' | 'carousel' | 'pricing-table' | 'google-maps' | 'social-icons' | 'alert' | 'timeline' | 'nav-menu' | 'breadcrumbs' | 'search' | 'posts-grid' | 'animated-headline' | 'flip-box' | 'countdown' | 'hotspot' | 'price-menu' | 'table' | 'modal-popup' | 'login' | 'share-buttons' | 'call-to-action' | 'faq' | 'contact-form' | 'team-member' | 'image-comparison' | 'coupon' | 'audio-player';
export interface ElementStyles {
    width?: string;
    height?: string;
    padding?: string;
    margin?: string;
    marginBottom?: string;
    display?: string;
    flexDirection?: 'row' | 'column' | 'row-reverse' | 'column-reverse';
    justifyContent?: string;
    alignItems?: string;
    gap?: string;
    fontSize?: string;
    fontWeight?: string;
    fontFamily?: string;
    lineHeight?: string;
    textAlign?: 'left' | 'center' | 'right' | 'justify';
    textTransform?: 'none' | 'capitalize' | 'uppercase' | 'lowercase' | 'full-width' | 'full-size-kana';
    color?: string;
    backgroundColor?: string;
    backgroundImage?: string;
    backgroundSize?: string;
    backgroundPosition?: string;
    backgroundRepeat?: 'repeat' | 'no-repeat' | 'repeat-x' | 'repeat-y' | 'space' | 'round';
    borderWidth?: string;
    borderColor?: string;
    border?: string;
    borderRadius?: string;
    boxShadow?: string;
    opacity?: number;
    transform?: string;
    transition?: string;
    [key: string]: any;
}
export interface ResponsiveStyles {
    mobile?: ElementStyles;
    tablet?: ElementStyles;
    desktop?: ElementStyles;
}
export interface PageStructure {
    id: string;
    title: string;
    slug: string;
    context: 'admin' | 'tenant' | 'public';
    tenantId?: string;
    elements: PageElement[];
    settings: PageSettings;
    metadata: PageMetadata;
}
export interface PageSettings {
    layout: 'full-width' | 'boxed';
    maxWidth?: string;
    backgroundColor?: string;
    customCSS?: string;
    customJS?: string;
}
export interface PageMetadata {
    createdAt: string;
    updatedAt: string;
    createdBy: string;
    version: number;
    published: boolean;
}
export interface ElementDefinition {
    type: ElementType;
    label: string;
    icon: string;
    category: 'basic' | 'media' | 'layout' | 'widget' | 'advanced' | 'form';
    defaultProps: Record<string, any>;
    defaultStyles: ElementStyles;
    controls: ElementControl[];
}
export interface ElementControl {
    id: string;
    label: string;
    type: 'text' | 'number' | 'color' | 'select' | 'toggle' | 'slider' | 'image' | 'textarea';
    section: 'content' | 'style' | 'advanced';
    defaultValue?: any;
    options?: {
        label: string;
        value: any;
    }[];
    min?: number;
    max?: number;
    step?: number;
}
export interface BuilderState {
    selectedElementId: string | null;
    hoveredElementId: string | null;
    draggedElementId: string | null;
    viewportMode: 'desktop' | 'tablet' | 'mobile';
    previewMode: boolean;
    history: PageStructure[];
    historyIndex: number;
}
//# sourceMappingURL=types.d.ts.map