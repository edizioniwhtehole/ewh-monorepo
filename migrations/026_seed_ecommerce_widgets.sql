-- ============================================================================
-- Seed E-Commerce and Advanced Widgets
-- 50+ widgets for complete e-commerce functionality
-- ============================================================================

BEGIN;

-- ============================================================================
-- E-COMMERCE WIDGETS (Products)
-- ============================================================================

INSERT INTO cms.widget_registry (widget_slug, widget_name, description, category, component_path, is_system, is_free) VALUES

-- Product Display (10)
('product-grid', 'Product Grid', 'Display products in a responsive grid layout', 'ecommerce', '@ewh/ecommerce-widgets/ProductGrid', true, true),
('product-list', 'Product List', 'Display products in a vertical list', 'ecommerce', '@ewh/ecommerce-widgets/ProductList', true, true),
('product-carousel', 'Product Carousel', 'Sliding carousel of products', 'ecommerce', '@ewh/ecommerce-widgets/ProductCarousel', true, true),
('product-card', 'Product Card', 'Single product card', 'ecommerce', '@ewh/ecommerce-widgets/ProductCard', true, true),
('product-quick-view', 'Quick View Modal', 'Quick product view in modal', 'ecommerce', '@ewh/ecommerce-widgets/ProductQuickView', true, false),
('product-compare', 'Product Comparison', 'Compare multiple products side by side', 'ecommerce', '@ewh/ecommerce-widgets/ProductCompare', true, false),
('product-filter', 'Product Filter', 'Advanced product filtering', 'ecommerce', '@ewh/ecommerce-widgets/ProductFilter', true, true),
('product-search', 'Product Search', 'Product search with autocomplete', 'ecommerce', '@ewh/ecommerce-widgets/ProductSearch', true, true),
('product-categories', 'Category Grid', 'Display product categories', 'ecommerce', '@ewh/ecommerce-widgets/ProductCategories', true, true),
('product-breadcrumbs', 'Breadcrumbs', 'Product navigation breadcrumbs', 'ecommerce', '@ewh/ecommerce-widgets/ProductBreadcrumbs', true, true),

-- Cart & Checkout (9)
('shopping-cart', 'Shopping Cart', 'Full shopping cart with line items', 'ecommerce', '@ewh/ecommerce-widgets/ShoppingCart', true, true),
('mini-cart', 'Mini Cart', 'Compact cart dropdown', 'ecommerce', '@ewh/ecommerce-widgets/MiniCart', true, true),
('cart-icon', 'Cart Icon', 'Cart icon with badge', 'ecommerce', '@ewh/ecommerce-widgets/CartIcon', true, true),
('checkout-form', 'Checkout Form', 'Complete checkout flow', 'ecommerce', '@ewh/ecommerce-widgets/CheckoutForm', true, true),
('checkout-steps', 'Checkout Steps', 'Multi-step checkout indicator', 'ecommerce', '@ewh/ecommerce-widgets/CheckoutSteps', true, true),
('payment-methods', 'Payment Methods', 'Available payment options', 'ecommerce', '@ewh/ecommerce-widgets/PaymentMethods', true, true),
('shipping-methods', 'Shipping Options', 'Shipping method selector', 'ecommerce', '@ewh/ecommerce-widgets/ShippingMethods', true, true),
('coupon-code', 'Coupon Code', 'Apply discount coupons', 'ecommerce', '@ewh/ecommerce-widgets/CouponCode', true, true),
('order-summary', 'Order Summary', 'Cart summary with totals', 'ecommerce', '@ewh/ecommerce-widgets/OrderSummary', true, true),

-- Reviews & Ratings (4)
('product-reviews', 'Product Reviews', 'Customer review list', 'ecommerce', '@ewh/ecommerce-widgets/ProductReviews', true, true),
('star-rating', 'Star Rating', 'Display and input star ratings', 'ecommerce', '@ewh/ecommerce-widgets/StarRating', true, true),
('review-form', 'Review Form', 'Write a review form', 'ecommerce', '@ewh/ecommerce-widgets/ReviewForm', true, true),
('review-stats', 'Review Statistics', 'Review breakdown and stats', 'ecommerce', '@ewh/ecommerce-widgets/ReviewStats', true, true),

-- Wishlist (3)
('wishlist', 'Wishlist', 'Saved products wishlist', 'ecommerce', '@ewh/ecommerce-widgets/Wishlist', true, true),
('wishlist-button', 'Add to Wishlist', 'Wishlist toggle button', 'ecommerce', '@ewh/ecommerce-widgets/WishlistButton', true, true),
('recently-viewed', 'Recently Viewed', 'Recently viewed products', 'ecommerce', '@ewh/ecommerce-widgets/RecentlyViewed', true, true),

-- Pricing & Offers (6)
('price-display', 'Price Display', 'Product price with variants', 'ecommerce', '@ewh/ecommerce-widgets/PriceDisplay', true, true),
('price-range', 'Price Range Filter', 'Filter by price range', 'ecommerce', '@ewh/ecommerce-widgets/PriceRange', true, true),
('sale-badge', 'Sale Badge', 'On-sale indicator badge', 'ecommerce', '@ewh/ecommerce-widgets/SaleBadge', true, true),
('discount-banner', 'Discount Banner', 'Promotional discount banner', 'ecommerce', '@ewh/ecommerce-widgets/DiscountBanner', true, true),
('countdown-timer', 'Countdown Timer', 'Sale countdown timer', 'ecommerce', '@ewh/ecommerce-widgets/CountdownTimer', true, true),
('price-alert', 'Price Alert', 'Price drop notification signup', 'ecommerce', '@ewh/ecommerce-widgets/PriceAlert', true, false),

-- Stock & Inventory (3)
('stock-status', 'Stock Status', 'In stock / out of stock indicator', 'ecommerce', '@ewh/ecommerce-widgets/StockStatus', true, true),
('low-stock-alert', 'Low Stock Alert', 'Low inventory warning', 'ecommerce', '@ewh/ecommerce-widgets/LowStockAlert', true, true),
('back-in-stock', 'Back in Stock', 'Restock notification signup', 'ecommerce', '@ewh/ecommerce-widgets/BackInStock', true, false),

-- Recommendations (6)
('related-products', 'Related Products', 'Similar products recommendation', 'ecommerce', '@ewh/ecommerce-widgets/RelatedProducts', true, true),
('upsell-products', 'Upsell Products', 'Premium alternatives', 'ecommerce', '@ewh/ecommerce-widgets/UpsellProducts', true, true),
('cross-sell', 'Cross-Sell', 'Complementary products', 'ecommerce', '@ewh/ecommerce-widgets/CrossSell', true, true),
('frequently-bought', 'Frequently Bought Together', 'Bundle suggestions', 'ecommerce', '@ewh/ecommerce-widgets/FrequentlyBought', true, false),
('bestsellers', 'Best Sellers', 'Top selling products', 'ecommerce', '@ewh/ecommerce-widgets/Bestsellers', true, true),
('new-arrivals', 'New Arrivals', 'Recently added products', 'ecommerce', '@ewh/ecommerce-widgets/NewArrivals', true, true),

-- Account & Orders (5)
('account-dashboard', 'Account Dashboard', 'Customer account overview', 'ecommerce', '@ewh/ecommerce-widgets/AccountDashboard', true, true),
('order-history', 'Order History', 'Past orders list', 'ecommerce', '@ewh/ecommerce-widgets/OrderHistory', true, true),
('order-tracking', 'Order Tracking', 'Track shipment status', 'ecommerce', '@ewh/ecommerce-widgets/OrderTracking', true, true),
('address-book', 'Address Book', 'Saved shipping addresses', 'ecommerce', '@ewh/ecommerce-widgets/AddressBook', true, true),
('saved-cards', 'Saved Payment Methods', 'Stored payment info', 'ecommerce', '@ewh/ecommerce-widgets/SavedCards', true, true),

-- Trust & Social (5)
('social-share', 'Social Share Buttons', 'Share product on social media', 'ecommerce', '@ewh/ecommerce-widgets/SocialShare', true, true),
('trust-badges', 'Trust Badges', 'Security and trust indicators', 'ecommerce', '@ewh/ecommerce-widgets/TrustBadges', true, true),
('secure-checkout-badge', 'Secure Checkout Badge', 'SSL/security badge', 'ecommerce', '@ewh/ecommerce-widgets/SecureCheckoutBadge', true, true),
('shipping-info', 'Shipping Information', 'Delivery details', 'ecommerce', '@ewh/ecommerce-widgets/ShippingInfo', true, true),
('return-policy', 'Return Policy', 'Return/refund policy widget', 'ecommerce', '@ewh/ecommerce-widgets/ReturnPolicy', true, true)

ON CONFLICT (widget_slug) DO NOTHING;

-- ============================================================================
-- MARKETING WIDGETS
-- ============================================================================

INSERT INTO cms.widget_registry (widget_slug, widget_name, description, category, component_path, is_system, is_free) VALUES

('lead-form', 'Lead Generation Form', 'Capture leads with custom form', 'marketing', '@ewh/marketing-widgets/LeadForm', true, true),
('newsletter-signup', 'Newsletter Signup', 'Email subscription form', 'marketing', '@ewh/marketing-widgets/NewsletterSignup', true, true),
('popup-form', 'Popup Form', 'Modal popup with form', 'marketing', '@ewh/marketing-widgets/PopupForm', true, false),
('exit-intent-popup', 'Exit Intent Popup', 'Triggered on exit attempt', 'marketing', '@ewh/marketing-widgets/ExitIntentPopup', true, false),
('progress-bar', 'Progress Bar', 'Animated progress indicator', 'marketing', '@ewh/marketing-widgets/ProgressBar', true, true),
('call-to-action', 'Call to Action', 'CTA button block', 'marketing', '@ewh/marketing-widgets/CallToAction', true, true),
('animated-headline', 'Animated Headline', 'Eye-catching animated text', 'marketing', '@ewh/marketing-widgets/AnimatedHeadline', true, false),
('flip-box', 'Flip Box', '3D flip card effect', 'marketing', '@ewh/marketing-widgets/FlipBox', true, false),
('hotspot', 'Hotspot', 'Interactive image hotspots', 'marketing', '@ewh/marketing-widgets/Hotspot', true, false),
('scratch-card', 'Scratch Card', 'Gamified scratch-off card', 'marketing', '@ewh/marketing-widgets/ScratchCard', true, false),
('spin-wheel', 'Spin the Wheel', 'Gamified prize wheel', 'marketing', '@ewh/marketing-widgets/SpinWheel', true, false),
('quiz', 'Quiz Builder', 'Interactive quiz', 'marketing', '@ewh/marketing-widgets/Quiz', true, false),
('survey', 'Survey Form', 'Customer survey', 'marketing', '@ewh/marketing-widgets/Survey', true, true)

ON CONFLICT (widget_slug) DO NOTHING;

-- ============================================================================
-- ANALYTICS WIDGETS
-- ============================================================================

INSERT INTO cms.widget_registry (widget_slug, widget_name, description, category, component_path, is_system, is_free) VALUES

('chart-line', 'Line Chart', 'Time-series line chart', 'analytics', '@ewh/analytics-widgets/ChartLine', true, true),
('chart-bar', 'Bar Chart', 'Vertical/horizontal bar chart', 'analytics', '@ewh/analytics-widgets/ChartBar', true, true),
('chart-pie', 'Pie Chart', 'Circular pie chart', 'analytics', '@ewh/analytics-widgets/ChartPie', true, true),
('chart-doughnut', 'Doughnut Chart', 'Doughnut chart with center text', 'analytics', '@ewh/analytics-widgets/ChartDoughnut', true, true),
('data-table', 'Data Table', 'Sortable data table', 'analytics', '@ewh/analytics-widgets/DataTable', true, true),
('kpi-card', 'KPI Card', 'Key performance indicator card', 'analytics', '@ewh/analytics-widgets/KPICard', true, true),
('trend-indicator', 'Trend Indicator', 'Up/down trend with percentage', 'analytics', '@ewh/analytics-widgets/TrendIndicator', true, true),
('real-time-counter', 'Real-time Counter', 'Live updating counter', 'analytics', '@ewh/analytics-widgets/RealTimeCounter', true, false),
('dashboard-widget', 'Dashboard Widget', 'Customizable dashboard panel', 'analytics', '@ewh/analytics-widgets/DashboardWidget', true, true)

ON CONFLICT (widget_slug) DO NOTHING;

-- ============================================================================
-- SOCIAL WIDGETS
-- ============================================================================

INSERT INTO cms.widget_registry (widget_slug, widget_name, description, category, component_path, is_system, is_free) VALUES

('social-feed', 'Social Media Feed', 'Aggregate social feed', 'social', '@ewh/social-widgets/SocialFeed', true, false),
('instagram-feed', 'Instagram Feed', 'Display Instagram posts', 'social', '@ewh/social-widgets/InstagramFeed', true, false),
('twitter-feed', 'Twitter Feed', 'Display Twitter timeline', 'social', '@ewh/social-widgets/TwitterFeed', true, false),
('facebook-feed', 'Facebook Feed', 'Display Facebook posts', 'social', '@ewh/social-widgets/FacebookFeed', true, false),
('social-icons', 'Social Icons', 'Social media icon links', 'social', '@ewh/social-widgets/SocialIcons', true, true),
('follow-buttons', 'Follow Buttons', 'Social follow buttons', 'social', '@ewh/social-widgets/FollowButtons', true, true),
('reviews-widget', 'Reviews Widget', 'Third-party reviews (Google, Yelp)', 'social', '@ewh/social-widgets/ReviewsWidget', true, false)

ON CONFLICT (widget_slug) DO NOTHING;

-- ============================================================================
-- CRM WIDGETS
-- ============================================================================

INSERT INTO cms.widget_registry (widget_slug, widget_name, description, category, component_path, is_system, is_free) VALUES

('contact-list', 'Contact List', 'CRM contacts list', 'crm', '@ewh/crm-widgets/ContactList', true, true),
('lead-score', 'Lead Score', 'Lead scoring indicator', 'crm', '@ewh/crm-widgets/LeadScore', true, false),
('pipeline-view', 'Pipeline View', 'Sales pipeline kanban', 'crm', '@ewh/crm-widgets/PipelineView', true, false),
('activity-timeline', 'Activity Timeline', 'Chronological activity feed', 'crm', '@ewh/crm-widgets/ActivityTimeline', true, true),
('task-list', 'Task List', 'CRM task manager', 'crm', '@ewh/crm-widgets/TaskList', true, true),
('deal-card', 'Deal Card', 'Deal information card', 'crm', '@ewh/crm-widgets/DealCard', true, true),
('email-thread', 'Email Thread', 'Email conversation view', 'crm', '@ewh/crm-widgets/EmailThread', true, false),
('meeting-scheduler', 'Meeting Scheduler', 'Calendar meeting booking', 'crm', '@ewh/crm-widgets/MeetingScheduler', true, false),
('notes-widget', 'Notes', 'CRM notes widget', 'crm', '@ewh/crm-widgets/NotesWidget', true, true),
('files-widget', 'Files', 'CRM file attachments', 'crm', '@ewh/crm-widgets/FilesWidget', true, true),
('tags-widget', 'Tags', 'Tag management', 'crm', '@ewh/crm-widgets/TagsWidget', true, true),
('custom-fields', 'Custom Fields', 'Dynamic custom fields', 'crm', '@ewh/crm-widgets/CustomFields', true, false)

ON CONFLICT (widget_slug) DO NOTHING;

-- ============================================================================
-- Create default owner permissions for all new widgets
-- ============================================================================

INSERT INTO cms.owner_widget_permissions (widget_slug, enabled_globally, enabled_for_new_tenants, allowed_contexts, allowed_page_types)
SELECT
  widget_slug,
  true,
  CASE
    WHEN is_free = true THEN true
    ELSE false
  END,
  ARRAY['internal', 'public', 'tenant']::TEXT[],
  ARRAY['admin', 'public', 'landing', 'tenant']::TEXT[]
FROM cms.widget_registry
WHERE widget_slug NOT IN (
  SELECT widget_slug FROM cms.owner_widget_permissions
);

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================

DO $$
DECLARE
  v_total INTEGER;
  v_ecommerce INTEGER;
  v_marketing INTEGER;
  v_analytics INTEGER;
  v_social INTEGER;
  v_crm INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM cms.widget_registry;
  SELECT COUNT(*) INTO v_ecommerce FROM cms.widget_registry WHERE category = 'ecommerce';
  SELECT COUNT(*) INTO v_marketing FROM cms.widget_registry WHERE category = 'marketing';
  SELECT COUNT(*) INTO v_analytics FROM cms.widget_registry WHERE category = 'analytics';
  SELECT COUNT(*) INTO v_social FROM cms.widget_registry WHERE category = 'social';
  SELECT COUNT(*) INTO v_crm FROM cms.widget_registry WHERE category = 'crm';

  RAISE NOTICE '✅ Widget Registry Seeded!';
  RAISE NOTICE '   Total Widgets: %', v_total;
  RAISE NOTICE '   E-Commerce: %', v_ecommerce;
  RAISE NOTICE '   Marketing: %', v_marketing;
  RAISE NOTICE '   Analytics: %', v_analytics;
  RAISE NOTICE '   Social: %', v_social;
  RAISE NOTICE '   CRM: %', v_crm;
  RAISE NOTICE '';
  RAISE NOTICE '🎯 All widgets have default owner permissions';
  RAISE NOTICE '🔓 Free widgets enabled for new tenants by default';
  RAISE NOTICE '🔒 Pro widgets require manual enabling';
END $$;
