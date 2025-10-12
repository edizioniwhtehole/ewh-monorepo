'use client';
import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import React, { useState, useCallback } from 'react';
import { Trash2, Settings, Eye, EyeOff, Monitor, Tablet, Smartphone, Undo, Redo, Layout, Type, Image as ImageIcon, Square, Circle, Video, Grid, Star, BarChart3, MessageSquare, List, ChevronDown, Layers, AlignJustify, Hash, FileText, CheckSquare, Send, Play, DollarSign, MapPin, Share2, AlertCircle, Clock, Menu, ChevronRight, Search, Calendar, Table2, Zap, BookOpen, Users, Mail, Percent } from 'lucide-react';
// Element definitions - Elementor-like comprehensive set
const defaultElements = [
    // Layout Elements
    {
        type: 'section',
        label: 'Section',
        icon: 'Layout',
        category: 'layout',
        defaultProps: {},
        defaultStyles: { padding: '60px 0', backgroundColor: '#ffffff' },
        controls: []
    },
    {
        type: 'column',
        label: 'Column',
        icon: 'Grid',
        category: 'layout',
        defaultProps: {},
        defaultStyles: { padding: '0 15px' },
        controls: []
    },
    // Basic Elements
    {
        type: 'heading',
        label: 'Heading',
        icon: 'Type',
        category: 'basic',
        defaultProps: { text: 'Your Heading', tag: 'h2' },
        defaultStyles: { fontSize: '32px', fontWeight: '700', color: '#000000' },
        controls: []
    },
    {
        type: 'text',
        label: 'Text Editor',
        icon: 'Type',
        category: 'basic',
        defaultProps: { content: 'Your text here...' },
        defaultStyles: { fontSize: '16px', lineHeight: '1.6', color: '#333333' },
        controls: []
    },
    {
        type: 'button',
        label: 'Button',
        icon: 'Square',
        category: 'basic',
        defaultProps: { text: 'Click Me', link: '#', size: 'md' },
        defaultStyles: {
            padding: '12px 24px',
            backgroundColor: '#0066cc',
            color: '#ffffff',
            borderRadius: '4px',
            fontWeight: '600'
        },
        controls: []
    },
    {
        type: 'image',
        label: 'Image',
        icon: 'ImageIcon',
        category: 'media',
        defaultProps: { src: '', alt: '', link: '' },
        defaultStyles: { width: '100%', height: 'auto' },
        controls: []
    },
    {
        type: 'video',
        label: 'Video',
        icon: 'Video',
        category: 'media',
        defaultProps: { url: '', autoplay: false, muted: false, loop: false },
        defaultStyles: { width: '100%' },
        controls: []
    },
    {
        type: 'spacer',
        label: 'Spacer',
        icon: 'Circle',
        category: 'basic',
        defaultProps: {},
        defaultStyles: { height: '50px' },
        controls: []
    },
    {
        type: 'divider',
        label: 'Divider',
        icon: 'Square',
        category: 'basic',
        defaultProps: { style: 'solid', weight: '1px' },
        defaultStyles: { borderTop: '1px solid #e0e0e0', margin: '20px 0', width: '100%' },
        controls: []
    },
    // Advanced Elements
    {
        type: 'icon',
        label: 'Icon',
        icon: 'Star',
        category: 'advanced',
        defaultProps: { icon: 'star', size: '50px' },
        defaultStyles: { fontSize: '50px', color: '#0066cc' },
        controls: []
    },
    {
        type: 'icon-box',
        label: 'Icon Box',
        icon: 'Square',
        category: 'advanced',
        defaultProps: {
            icon: 'star',
            title: 'Icon Box Title',
            description: 'Your description text goes here',
            position: 'top'
        },
        defaultStyles: {
            padding: '30px',
            textAlign: 'center',
            borderRadius: '8px',
            backgroundColor: '#f9fafb'
        },
        controls: []
    },
    {
        type: 'star-rating',
        label: 'Star Rating',
        icon: 'Star',
        category: 'advanced',
        defaultProps: { rating: 5, maxRating: 5 },
        defaultStyles: { fontSize: '24px', color: '#fbbf24' },
        controls: []
    },
    {
        type: 'progress-bar',
        label: 'Progress Bar',
        icon: 'BarChart3',
        category: 'advanced',
        defaultProps: {
            title: 'Progress',
            percentage: 75,
            showPercentage: true
        },
        defaultStyles: {
            backgroundColor: '#e5e7eb',
            color: '#0066cc',
            height: '30px',
            borderRadius: '15px'
        },
        controls: []
    },
    {
        type: 'counter',
        label: 'Counter',
        icon: 'Hash',
        category: 'advanced',
        defaultProps: {
            endValue: 1000,
            prefix: '',
            suffix: '+',
            duration: 2000
        },
        defaultStyles: {
            fontSize: '48px',
            fontWeight: '700',
            color: '#0066cc',
            textAlign: 'center'
        },
        controls: []
    },
    {
        type: 'testimonial',
        label: 'Testimonial',
        icon: 'MessageSquare',
        category: 'advanced',
        defaultProps: {
            content: 'This is an amazing product! Highly recommended.',
            author: 'John Doe',
            position: 'CEO, Company',
            image: '',
            rating: 5
        },
        defaultStyles: {
            padding: '30px',
            backgroundColor: '#ffffff',
            borderRadius: '8px',
            boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
        },
        controls: []
    },
    {
        type: 'accordion',
        label: 'Accordion',
        icon: 'ChevronDown',
        category: 'advanced',
        defaultProps: {
            items: [
                { title: 'Accordion Item 1', content: 'Content for item 1' },
                { title: 'Accordion Item 2', content: 'Content for item 2' }
            ]
        },
        defaultStyles: {},
        controls: []
    },
    {
        type: 'tabs',
        label: 'Tabs',
        icon: 'Layers',
        category: 'advanced',
        defaultProps: {
            items: [
                { title: 'Tab 1', content: 'Content for tab 1' },
                { title: 'Tab 2', content: 'Content for tab 2' }
            ]
        },
        defaultStyles: {},
        controls: []
    },
    {
        type: 'toggle',
        label: 'Toggle',
        icon: 'AlignJustify',
        category: 'advanced',
        defaultProps: {
            title: 'Toggle Title',
            content: 'Toggle content goes here',
            isOpen: false
        },
        defaultStyles: {
            padding: '20px',
            backgroundColor: '#ffffff',
            border: '1px solid #e5e7eb',
            borderRadius: '8px'
        },
        controls: []
    },
    {
        type: 'list',
        label: 'Icon List',
        icon: 'List',
        category: 'advanced',
        defaultProps: {
            items: [
                { icon: 'check', text: 'List item 1' },
                { icon: 'check', text: 'List item 2' },
                { icon: 'check', text: 'List item 3' }
            ],
            iconColor: '#10b981'
        },
        defaultStyles: {},
        controls: []
    },
    // Form Elements
    {
        type: 'form',
        label: 'Form',
        icon: 'FileText',
        category: 'form',
        defaultProps: {
            action: '',
            method: 'POST',
            submitText: 'Submit'
        },
        defaultStyles: { padding: '20px' },
        controls: []
    },
    {
        type: 'input',
        label: 'Input Field',
        icon: 'Type',
        category: 'form',
        defaultProps: {
            label: 'Field Label',
            placeholder: 'Enter text...',
            type: 'text',
            required: false,
            name: 'field'
        },
        defaultStyles: { marginBottom: '15px' },
        controls: []
    },
    {
        type: 'textarea',
        label: 'Textarea',
        icon: 'AlignJustify',
        category: 'form',
        defaultProps: {
            label: 'Message',
            placeholder: 'Enter your message...',
            rows: 4,
            required: false,
            name: 'message'
        },
        defaultStyles: { marginBottom: '15px' },
        controls: []
    },
    {
        type: 'select',
        label: 'Select',
        icon: 'ChevronDown',
        category: 'form',
        defaultProps: {
            label: 'Select Option',
            options: ['Option 1', 'Option 2', 'Option 3'],
            required: false,
            name: 'select'
        },
        defaultStyles: { marginBottom: '15px' },
        controls: []
    },
    {
        type: 'checkbox',
        label: 'Checkbox',
        icon: 'CheckSquare',
        category: 'form',
        defaultProps: {
            label: 'I agree to terms',
            required: false,
            name: 'checkbox'
        },
        defaultStyles: { marginBottom: '15px' },
        controls: []
    },
    {
        type: 'submit',
        label: 'Submit Button',
        icon: 'Send',
        category: 'form',
        defaultProps: { text: 'Submit' },
        defaultStyles: {
            padding: '12px 30px',
            backgroundColor: '#0066cc',
            color: '#ffffff',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: '600'
        },
        controls: []
    },
    // Advanced Interactive Elements
    {
        type: 'carousel',
        label: 'Carousel',
        icon: 'Play',
        category: 'advanced',
        defaultProps: {
            images: [],
            autoplay: true,
            interval: 3000
        },
        defaultStyles: { width: '100%' },
        controls: []
    },
    {
        type: 'pricing-table',
        label: 'Pricing Table',
        icon: 'DollarSign',
        category: 'advanced',
        defaultProps: {
            title: 'Basic Plan',
            price: '29',
            currency: '$',
            period: 'month',
            features: ['Feature 1', 'Feature 2', 'Feature 3'],
            buttonText: 'Get Started'
        },
        defaultStyles: {
            padding: '40px 30px',
            textAlign: 'center',
            border: '2px solid #e5e7eb',
            borderRadius: '12px',
            backgroundColor: '#ffffff'
        },
        controls: []
    },
    {
        type: 'google-maps',
        label: 'Google Maps',
        icon: 'MapPin',
        category: 'advanced',
        defaultProps: {
            address: 'New York, NY',
            zoom: 14,
            height: '400px'
        },
        defaultStyles: { width: '100%' },
        controls: []
    },
    {
        type: 'social-icons',
        label: 'Social Icons',
        icon: 'Share2',
        category: 'advanced',
        defaultProps: {
            icons: [
                { platform: 'facebook', url: '#' },
                { platform: 'twitter', url: '#' },
                { platform: 'instagram', url: '#' }
            ],
            size: '40px'
        },
        defaultStyles: { display: 'flex', gap: '15px', justifyContent: 'center' },
        controls: []
    },
    {
        type: 'alert',
        label: 'Alert Box',
        icon: 'AlertCircle',
        category: 'advanced',
        defaultProps: {
            type: 'info',
            title: 'Information',
            message: 'This is an informational message',
            dismissible: true
        },
        defaultStyles: {
            padding: '15px 20px',
            borderRadius: '8px',
            marginBottom: '20px'
        },
        controls: []
    },
    {
        type: 'timeline',
        label: 'Timeline',
        icon: 'Clock',
        category: 'advanced',
        defaultProps: {
            items: [
                { year: '2024', title: 'Event Title 1', description: 'Event description' },
                { year: '2023', title: 'Event Title 2', description: 'Event description' }
            ]
        },
        defaultStyles: {},
        controls: []
    },
    // Elementor Pro & Crocoblock Elements
    {
        type: 'nav-menu',
        label: 'Nav Menu',
        icon: 'Menu',
        category: 'advanced',
        defaultProps: {
            items: [
                { label: 'Home', url: '/' },
                { label: 'About', url: '/about' },
                { label: 'Services', url: '/services' },
                { label: 'Contact', url: '/contact' }
            ],
            layout: 'horizontal'
        },
        defaultStyles: {
            display: 'flex',
            gap: '30px',
            padding: '20px 0'
        },
        controls: []
    },
    {
        type: 'breadcrumbs',
        label: 'Breadcrumbs',
        icon: 'ChevronRight',
        category: 'advanced',
        defaultProps: {
            separator: '/',
            items: [
                { label: 'Home', url: '/' },
                { label: 'Category', url: '/category' },
                { label: 'Current Page', url: '#' }
            ]
        },
        defaultStyles: {
            display: 'flex',
            gap: '10px',
            fontSize: '14px',
            color: '#6b7280'
        },
        controls: []
    },
    {
        type: 'search',
        label: 'Search',
        icon: 'Search',
        category: 'form',
        defaultProps: {
            placeholder: 'Search...',
            buttonText: 'Search',
            action: '/search'
        },
        defaultStyles: {
            display: 'flex',
            gap: '10px'
        },
        controls: []
    },
    {
        type: 'posts-grid',
        label: 'Posts Grid',
        icon: 'Grid',
        category: 'advanced',
        defaultProps: {
            columns: 3,
            postsPerPage: 9,
            showExcerpt: true,
            showDate: true,
            showAuthor: true
        },
        defaultStyles: {
            display: 'grid',
            gap: '30px'
        },
        controls: []
    },
    {
        type: 'animated-headline',
        label: 'Animated Headline',
        icon: 'Zap',
        category: 'advanced',
        defaultProps: {
            beforeText: 'We are',
            animatedWords: ['Creative', 'Professional', 'Innovative'],
            afterText: 'designers',
            animationStyle: 'typing'
        },
        defaultStyles: {
            fontSize: '48px',
            fontWeight: '700'
        },
        controls: []
    },
    {
        type: 'flip-box',
        label: 'Flip Box',
        icon: 'Square',
        category: 'advanced',
        defaultProps: {
            frontTitle: 'Front Side',
            frontContent: 'Hover to flip',
            backTitle: 'Back Side',
            backContent: 'Hidden content here',
            direction: 'horizontal'
        },
        defaultStyles: {
            width: '300px',
            height: '300px'
        },
        controls: []
    },
    {
        type: 'countdown',
        label: 'Countdown',
        icon: 'Calendar',
        category: 'advanced',
        defaultProps: {
            targetDate: '2025-12-31T23:59:59',
            showDays: true,
            showHours: true,
            showMinutes: true,
            showSeconds: true
        },
        defaultStyles: {
            display: 'flex',
            gap: '20px',
            fontSize: '32px',
            fontWeight: '700'
        },
        controls: []
    },
    {
        type: 'hotspot',
        label: 'Hotspot',
        icon: 'MapPin',
        category: 'advanced',
        defaultProps: {
            imageUrl: '',
            hotspots: [
                { x: 30, y: 40, tooltip: 'Point 1', link: '#' },
                { x: 70, y: 60, tooltip: 'Point 2', link: '#' }
            ]
        },
        defaultStyles: {
            position: 'relative',
            width: '100%'
        },
        controls: []
    },
    {
        type: 'price-menu',
        label: 'Price Menu',
        icon: 'DollarSign',
        category: 'advanced',
        defaultProps: {
            items: [
                { name: 'Item 1', description: 'Description', price: '25', image: '' },
                { name: 'Item 2', description: 'Description', price: '35', image: '' }
            ]
        },
        defaultStyles: {
            display: 'flex',
            flexDirection: 'column',
            gap: '20px'
        },
        controls: []
    },
    {
        type: 'table',
        label: 'Data Table',
        icon: 'Table2',
        category: 'advanced',
        defaultProps: {
            headers: ['Column 1', 'Column 2', 'Column 3'],
            rows: [
                ['Data 1', 'Data 2', 'Data 3'],
                ['Data 4', 'Data 5', 'Data 6']
            ],
            striped: true,
            sortable: true
        },
        defaultStyles: {
            width: '100%',
            borderCollapse: 'collapse'
        },
        controls: []
    },
    {
        type: 'modal-popup',
        label: 'Modal Popup',
        icon: 'Square',
        category: 'advanced',
        defaultProps: {
            triggerText: 'Open Modal',
            title: 'Modal Title',
            content: 'Modal content goes here'
        },
        defaultStyles: {},
        controls: []
    },
    {
        type: 'login',
        label: 'Login Form',
        icon: 'Users',
        category: 'form',
        defaultProps: {
            showRegisterLink: true,
            showForgotPassword: true,
            redirectUrl: '/'
        },
        defaultStyles: {
            padding: '30px',
            maxWidth: '400px'
        },
        controls: []
    },
    {
        type: 'share-buttons',
        label: 'Share Buttons',
        icon: 'Share2',
        category: 'advanced',
        defaultProps: {
            networks: ['facebook', 'twitter', 'linkedin', 'whatsapp', 'email'],
            style: 'rounded',
            showLabels: true
        },
        defaultStyles: {
            display: 'flex',
            gap: '10px'
        },
        controls: []
    },
    {
        type: 'call-to-action',
        label: 'Call To Action',
        icon: 'Zap',
        category: 'advanced',
        defaultProps: {
            title: 'Ready to get started?',
            description: 'Join thousands of satisfied customers today',
            buttonText: 'Get Started Now',
            buttonUrl: '#',
            layout: 'left'
        },
        defaultStyles: {
            padding: '60px 40px',
            backgroundColor: '#0066cc',
            color: '#ffffff',
            borderRadius: '12px'
        },
        controls: []
    },
    {
        type: 'faq',
        label: 'FAQ',
        icon: 'BookOpen',
        category: 'advanced',
        defaultProps: {
            items: [
                { question: 'Question 1?', answer: 'Answer to question 1' },
                { question: 'Question 2?', answer: 'Answer to question 2' },
                { question: 'Question 3?', answer: 'Answer to question 3' }
            ]
        },
        defaultStyles: {
            display: 'flex',
            flexDirection: 'column',
            gap: '15px'
        },
        controls: []
    },
    {
        type: 'contact-form',
        label: 'Contact Form',
        icon: 'Mail',
        category: 'form',
        defaultProps: {
            fields: ['name', 'email', 'subject', 'message'],
            submitText: 'Send Message',
            emailTo: 'info@example.com'
        },
        defaultStyles: {
            display: 'flex',
            flexDirection: 'column',
            gap: '20px',
            maxWidth: '600px'
        },
        controls: []
    },
    {
        type: 'team-member',
        label: 'Team Member',
        icon: 'Users',
        category: 'advanced',
        defaultProps: {
            name: 'John Doe',
            position: 'CEO & Founder',
            image: '',
            bio: 'Short bio about the team member',
            social: {
                linkedin: '#',
                twitter: '#',
                email: 'john@example.com'
            }
        },
        defaultStyles: {
            textAlign: 'center',
            padding: '30px'
        },
        controls: []
    },
    {
        type: 'image-comparison',
        label: 'Image Comparison',
        icon: 'Circle',
        category: 'advanced',
        defaultProps: {
            beforeImage: '',
            afterImage: '',
            beforeLabel: 'Before',
            afterLabel: 'After'
        },
        defaultStyles: {
            position: 'relative',
            width: '100%',
            maxWidth: '800px'
        },
        controls: []
    },
    {
        type: 'coupon',
        label: 'Coupon',
        icon: 'Percent',
        category: 'advanced',
        defaultProps: {
            code: 'SAVE20',
            discount: '20% OFF',
            description: 'Use this code at checkout',
            expiry: '2025-12-31'
        },
        defaultStyles: {
            border: '2px dashed #0066cc',
            padding: '30px',
            textAlign: 'center',
            borderRadius: '8px'
        },
        controls: []
    },
    {
        type: 'audio-player',
        label: 'Audio Player',
        icon: 'Play',
        category: 'media',
        defaultProps: {
            src: '',
            title: 'Audio Title',
            artist: 'Artist Name',
            showPlaylist: false
        },
        defaultStyles: {
            width: '100%',
            maxWidth: '600px'
        },
        controls: []
    }
];
export function VisualPageBuilder({ page: initialPage, onSave, onPublish, context, availableWidgets = [] }) {
    const [page, setPage] = useState(initialPage);
    const [state, setState] = useState({
        selectedElementId: null,
        hoveredElementId: null,
        draggedElementId: null,
        viewportMode: 'desktop',
        previewMode: false,
        history: [initialPage],
        historyIndex: 0
    });
    const [isSaving, setIsSaving] = useState(false);
    const [leftPanelTab, setLeftPanelTab] = useState('elements');
    const [rightPanelTab, setRightPanelTab] = useState('content');
    const [showPageSettings, setShowPageSettings] = useState(false);
    const [showDeviceManager, setShowDeviceManager] = useState(false);
    const [canvasMode, setCanvasMode] = useState('light');
    const [mobileResolution, setMobileResolution] = useState('iphone-13');
    const [mobileResolutions, setMobileResolutions] = useState({
        'iphone-13': { width: '390px', label: 'iPhone 13/14 (390px)' }
    });
    const [allDevices, setAllDevices] = useState([]);
    const [deviceFormData, setDeviceFormData] = useState({
        device_key: '',
        device_name: '',
        device_type: 'mobile',
        width_px: 390,
        height_px: 844,
        label: '',
        manufacturer: '',
        model: '',
        release_year: new Date().getFullYear(),
        is_default: false,
        display_order: 0
    });
    const [editingDeviceId, setEditingDeviceId] = useState(null);
    // Load device resolutions from API
    React.useEffect(() => {
        const loadDeviceResolutions = async () => {
            try {
                const response = await fetch('http://localhost:5000/api/device-resolutions/mobile');
                const data = await response.json();
                if (data.success && data.data) {
                    const resolutions = {};
                    let defaultKey = 'iphone-13';
                    data.data.forEach((device) => {
                        resolutions[device.device_key] = {
                            width: `${device.width_px}px`,
                            label: device.label
                        };
                        if (device.is_default) {
                            defaultKey = device.device_key;
                        }
                    });
                    setMobileResolutions(resolutions);
                    setMobileResolution(defaultKey);
                }
            }
            catch (error) {
                console.error('Failed to load device resolutions:', error);
                // Keep default fallback resolutions
            }
        };
        loadDeviceResolutions();
        // Also load all devices initially for the device manager
        loadAllDevices();
    }, []);
    // Load all devices for device manager
    const loadAllDevices = async () => {
        try {
            const response = await fetch('http://localhost:5000/api/device-resolutions');
            const data = await response.json();
            if (data.success && data.data) {
                setAllDevices(data.data);
            }
        }
        catch (error) {
            console.error('Failed to load all devices:', error);
        }
    };
    // Save device (create or update)
    const saveDevice = async () => {
        try {
            const url = editingDeviceId
                ? `http://localhost:5000/api/device-resolutions/${editingDeviceId}`
                : 'http://localhost:5000/api/device-resolutions';
            const method = editingDeviceId ? 'PATCH' : 'POST';
            const response = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(deviceFormData)
            });
            const data = await response.json();
            if (data.success) {
                alert(editingDeviceId ? 'Device updated successfully!' : 'Device created successfully!');
                loadAllDevices();
                resetDeviceForm();
                // Reload mobile resolutions if it's a mobile device
                if (deviceFormData.device_type === 'mobile') {
                    const mobileResponse = await fetch('http://localhost:5000/api/device-resolutions/mobile');
                    const mobileData = await mobileResponse.json();
                    if (mobileData.success && mobileData.data) {
                        const resolutions = {};
                        mobileData.data.forEach((device) => {
                            resolutions[device.device_key] = {
                                width: `${device.width_px}px`,
                                label: device.label
                            };
                        });
                        setMobileResolutions(resolutions);
                    }
                }
            }
            else {
                alert(`Error: ${data.error}`);
            }
        }
        catch (error) {
            alert(`Failed to save device: ${error.message}`);
        }
    };
    // Delete device
    const deleteDevice = async (id) => {
        if (!confirm('Are you sure you want to deactivate this device?'))
            return;
        try {
            const response = await fetch(`http://localhost:5000/api/device-resolutions/${id}`, {
                method: 'DELETE'
            });
            const data = await response.json();
            if (data.success) {
                alert('Device deactivated successfully!');
                loadAllDevices();
            }
            else {
                alert(`Error: ${data.error}`);
            }
        }
        catch (error) {
            alert(`Failed to delete device: ${error.message}`);
        }
    };
    // Edit device
    const editDevice = (device) => {
        setEditingDeviceId(device.id);
        setDeviceFormData({
            device_key: device.device_key,
            device_name: device.device_name,
            device_type: device.device_type,
            width_px: device.width_px,
            height_px: device.height_px,
            label: device.label,
            manufacturer: device.manufacturer || '',
            model: device.model || '',
            release_year: device.release_year || new Date().getFullYear(),
            is_default: device.is_default,
            display_order: device.display_order
        });
    };
    // Reset device form
    const resetDeviceForm = () => {
        setEditingDeviceId(null);
        setDeviceFormData({
            device_key: '',
            device_name: '',
            device_type: 'mobile',
            width_px: 390,
            height_px: 844,
            label: '',
            manufacturer: '',
            model: '',
            release_year: new Date().getFullYear(),
            is_default: false,
            display_order: 0
        });
    };
    // Add element to history
    const addToHistory = useCallback((newPage) => {
        setState(prev => {
            const newHistory = prev.history.slice(0, prev.historyIndex + 1);
            newHistory.push(newPage);
            return {
                ...prev,
                history: newHistory,
                historyIndex: newHistory.length - 1
            };
        });
    }, []);
    // Undo/Redo
    const undo = useCallback(() => {
        if (state.historyIndex > 0) {
            const newIndex = state.historyIndex - 1;
            setPage(state.history[newIndex]);
            setState(prev => ({ ...prev, historyIndex: newIndex }));
        }
    }, [state.historyIndex, state.history]);
    const redo = useCallback(() => {
        if (state.historyIndex < state.history.length - 1) {
            const newIndex = state.historyIndex + 1;
            setPage(state.history[newIndex]);
            setState(prev => ({ ...prev, historyIndex: newIndex }));
        }
    }, [state.historyIndex, state.history]);
    // Add element
    const addElement = useCallback((type, parentId) => {
        const definition = [...defaultElements, ...availableWidgets].find(d => d.type === type);
        if (!definition)
            return;
        const newElement = {
            id: `el-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            type,
            props: { ...definition.defaultProps },
            styles: { ...definition.defaultStyles },
            children: []
        };
        setPage(prev => {
            const newPage = { ...prev };
            if (parentId) {
                // Add to specific parent
                const addToParent = (elements) => {
                    return elements.map(el => {
                        if (el.id === parentId) {
                            return { ...el, children: [...(el.children || []), newElement] };
                        }
                        if (el.children) {
                            return { ...el, children: addToParent(el.children) };
                        }
                        return el;
                    });
                };
                newPage.elements = addToParent(prev.elements || []);
            }
            else {
                // Add to root
                newPage.elements = [...(prev.elements || []), newElement];
            }
            addToHistory(newPage);
            return newPage;
        });
        setState(prev => ({ ...prev, selectedElementId: newElement.id }));
    }, [availableWidgets, addToHistory]);
    // Delete element
    const deleteElement = useCallback((elementId) => {
        setPage(prev => {
            const removeElement = (elements) => {
                return elements.filter(el => {
                    if (el.id === elementId)
                        return false;
                    if (el.children) {
                        el.children = removeElement(el.children);
                    }
                    return true;
                });
            };
            const newPage = { ...prev, elements: removeElement(prev.elements) };
            addToHistory(newPage);
            return newPage;
        });
        setState(prev => ({ ...prev, selectedElementId: null }));
    }, [addToHistory]);
    // Update element
    const updateElement = useCallback((elementId, updates) => {
        setPage(prev => {
            const updateInTree = (elements) => {
                return elements.map(el => {
                    if (el.id === elementId) {
                        return { ...el, ...updates };
                    }
                    if (el.children) {
                        return { ...el, children: updateInTree(el.children) };
                    }
                    return el;
                });
            };
            const newPage = { ...prev, elements: updateInTree(prev.elements) };
            addToHistory(newPage);
            return newPage;
        });
    }, [addToHistory]);
    // Find element by ID
    const findElement = (elements, elementId) => {
        for (const el of elements) {
            if (el.id === elementId)
                return el;
            if (el.children) {
                const found = findElement(el.children, elementId);
                if (found)
                    return found;
            }
        }
        return null;
    };
    // Save
    const handleSave = async () => {
        setIsSaving(true);
        try {
            await onSave(page);
        }
        finally {
            setIsSaving(false);
        }
    };
    // Render element
    const renderElement = (element, depth = 0) => {
        const isSelected = state.selectedElementId === element.id;
        const isHovered = state.hoveredElementId === element.id;
        // Merge responsive styles based on viewport mode
        const getEffectiveStyles = () => {
            let styles = { ...element.styles };
            if (state.viewportMode === 'tablet' && element.responsive?.tablet) {
                styles = { ...styles, ...element.responsive.tablet };
            }
            else if (state.viewportMode === 'mobile' && element.responsive?.mobile) {
                styles = { ...styles, ...element.responsive.mobile };
            }
            return styles;
        };
        return (_jsxs("div", { className: `relative group ${isSelected ? 'ring-2 ring-blue-500' : ''} ${isHovered ? 'ring-1 ring-blue-300' : ''}`, style: getEffectiveStyles(), onClick: (e) => {
                e.stopPropagation();
                setState(prev => ({ ...prev, selectedElementId: element.id }));
            }, onMouseEnter: () => setState(prev => ({ ...prev, hoveredElementId: element.id })), onMouseLeave: () => setState(prev => ({ ...prev, hoveredElementId: null })), children: [!state.previewMode && (isSelected || isHovered) && (_jsx("div", { className: "absolute top-0 right-0 z-10 flex items-center gap-1 p-1 bg-blue-500 rounded-bl", children: _jsx("button", { onClick: (e) => {
                            e.stopPropagation();
                            deleteElement(element.id);
                        }, className: "p-1 text-white hover:bg-blue-600 rounded", children: _jsx(Trash2, { className: "w-3 h-3" }) }) })), element.type === 'section' && (_jsx("div", { className: `container mx-auto ${!state.previewMode
                        ? `border-2 border-dashed min-h-[100px] flex gap-4 p-4 ${canvasMode === 'dark'
                            ? 'border-blue-400 bg-neutral-800/30'
                            : 'border-blue-400 bg-blue-50/30'}`
                        : ''}`, style: !state.previewMode ? getEffectiveStyles() : getEffectiveStyles(), children: !element.children || element.children.length === 0 ? (!state.previewMode && (_jsx("div", { className: `flex-1 flex items-center justify-center text-sm font-medium ${canvasMode === 'dark' ? 'text-blue-300' : 'text-blue-600'}`, children: "\u2193 Click \"Column\" to add columns here \u2193" }))) : (element.children.map(child => renderElement(child, depth + 1))) })), element.type === 'column' && (_jsx("div", { className: `flex-1 ${!state.previewMode
                        ? `border-2 border-dashed min-h-[80px] p-3 ${canvasMode === 'dark'
                            ? 'border-green-400 bg-neutral-700/30'
                            : 'border-green-500 bg-green-50/30'}`
                        : ''}`, style: !state.previewMode ? getEffectiveStyles() : getEffectiveStyles(), children: !element.children || element.children.length === 0 ? (!state.previewMode && (_jsx("div", { className: `flex items-center justify-center text-xs font-medium h-full ${canvasMode === 'dark' ? 'text-green-300' : 'text-green-700'}`, children: "+ Add elements +" }))) : (element.children.map(child => renderElement(child, depth + 1))) })), element.type === 'heading' && (React.createElement(element.props.tag || 'h2', { style: getEffectiveStyles() }, element.props.text)), element.type === 'text' && (_jsx("div", { style: getEffectiveStyles(), dangerouslySetInnerHTML: { __html: element.props.content || '' } })), element.type === 'button' && (_jsx("a", { href: element.props.link, style: getEffectiveStyles(), children: element.props.text })), element.type === 'image' && (element.props.link ? (_jsx("a", { href: element.props.link, children: _jsx("img", { src: element.props.src, alt: element.props.alt, style: getEffectiveStyles() }) })) : (_jsx("img", { src: element.props.src, alt: element.props.alt, style: getEffectiveStyles() }))), element.type === 'video' && (_jsx("div", { style: getEffectiveStyles(), children: element.props.url ? (element.props.url.includes('youtube.com') || element.props.url.includes('youtu.be') ? (_jsx("iframe", { width: "100%", height: "400", src: element.props.url, frameBorder: "0", allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture", allowFullScreen: true, style: getEffectiveStyles() })) : (_jsx("video", { src: element.props.url, controls: true, autoPlay: element.props.autoplay, muted: element.props.muted, loop: element.props.loop, style: getEffectiveStyles() }))) : (_jsx("div", { className: "bg-gray-200 h-64 flex items-center justify-center text-gray-500", children: "No video URL provided" })) })), element.type === 'spacer' && _jsx("div", { style: getEffectiveStyles() }), element.type === 'divider' && _jsx("hr", { style: getEffectiveStyles() }), element.type === 'icon' && (_jsx("div", { style: { textAlign: 'center', ...getEffectiveStyles() }, children: _jsx(Star, { style: { fontSize: element.props.size, color: getEffectiveStyles().color } }) })), element.type === 'icon-box' && (_jsx("div", { style: getEffectiveStyles(), children: _jsxs("div", { style: { textAlign: element.props.position || 'center' }, children: [_jsx(Star, { style: { fontSize: '40px', marginBottom: '15px' } }), _jsx("h3", { style: { fontSize: '24px', fontWeight: '600', marginBottom: '10px' }, children: element.props.title }), _jsx("p", { style: { fontSize: '16px', lineHeight: '1.6' }, children: element.props.description })] }) })), element.type === 'star-rating' && (_jsx("div", { style: getEffectiveStyles(), children: [...Array(element.props.maxRating || 5)].map((_, i) => (_jsx(Star, { style: {
                            fontSize: getEffectiveStyles().fontSize,
                            color: i < (element.props.rating || 0) ? getEffectiveStyles().color : '#d1d5db',
                            display: 'inline-block',
                            marginRight: '5px'
                        }, fill: i < (element.props.rating || 0) ? getEffectiveStyles().color : '#d1d5db' }, i))) })), element.type === 'progress-bar' && (_jsxs("div", { style: getEffectiveStyles(), children: [element.props.title && (_jsx("div", { style: { marginBottom: '10px', fontWeight: '600' }, children: element.props.title })), _jsx("div", { style: {
                                width: '100%',
                                backgroundColor: getEffectiveStyles().backgroundColor,
                                borderRadius: getEffectiveStyles().borderRadius,
                                height: getEffectiveStyles().height,
                                position: 'relative',
                                overflow: 'hidden'
                            }, children: _jsx("div", { style: {
                                    width: `${element.props.percentage || 0}%`,
                                    backgroundColor: getEffectiveStyles().color,
                                    height: '100%',
                                    borderRadius: getEffectiveStyles().borderRadius,
                                    transition: 'width 0.3s ease'
                                }, children: element.props.showPercentage && (_jsxs("span", { style: {
                                        position: 'absolute',
                                        right: '10px',
                                        top: '50%',
                                        transform: 'translateY(-50%)',
                                        fontWeight: '600',
                                        fontSize: '14px'
                                    }, children: [element.props.percentage, "%"] })) }) })] })), element.type === 'counter' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("span", { children: element.props.prefix }), _jsx("span", { children: element.props.endValue }), _jsx("span", { children: element.props.suffix })] })), element.type === 'testimonial' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("div", { style: { marginBottom: '20px' }, children: [...Array(element.props.rating || 5)].map((_, i) => (_jsx(Star, { style: { fontSize: '20px', color: '#fbbf24', display: 'inline-block', marginRight: '3px' }, fill: "#fbbf24" }, i))) }), _jsxs("p", { style: { fontSize: '18px', fontStyle: 'italic', marginBottom: '20px' }, children: ["\"", element.props.content, "\""] }), _jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: '15px' }, children: [element.props.image && (_jsx("img", { src: element.props.image, alt: element.props.author, style: { width: '60px', height: '60px', borderRadius: '50%' } })), _jsxs("div", { children: [_jsx("div", { style: { fontWeight: '600', fontSize: '16px' }, children: element.props.author }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: element.props.position })] })] })] })), element.type === 'accordion' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsx("div", { style: { borderBottom: '1px solid #e5e7eb', padding: '15px 0' }, children: _jsxs("div", { style: { fontWeight: '600', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }, children: [item.title, _jsx(ChevronDown, {})] }) }, index))) })), element.type === 'tabs' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("div", { style: { display: 'flex', borderBottom: '2px solid #e5e7eb', marginBottom: '20px' }, children: (element.props.items || []).map((item, index) => (_jsx("div", { style: {
                                    padding: '10px 20px',
                                    cursor: 'pointer',
                                    borderBottom: index === 0 ? '2px solid #0066cc' : 'none',
                                    fontWeight: index === 0 ? '600' : '400'
                                }, children: item.title }, index))) }), _jsx("div", { children: element.props.items?.[0]?.content })] })), element.type === 'toggle' && (_jsx("div", { style: getEffectiveStyles(), children: _jsxs("div", { style: { fontWeight: '600', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }, children: [element.props.title, _jsx(ChevronDown, {})] }) })), element.type === 'list' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px' }, children: [_jsx(Square, { style: { fontSize: '20px', color: element.props.iconColor || '#10b981' } }), _jsx("span", { children: item.text })] }, index))) })), element.type === 'form' && (_jsx("form", { action: element.props.action, method: element.props.method, style: getEffectiveStyles(), children: element.children && element.children.length > 0 ? (element.children.map(child => renderElement(child, depth + 1))) : (_jsx("div", { style: { textAlign: 'center', padding: '40px', color: '#9ca3af' }, children: "Add form fields here" })) })), element.type === 'input' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("label", { style: { display: 'block', marginBottom: '5px', fontWeight: '500' }, children: element.props.label }), _jsx("input", { type: element.props.type || 'text', placeholder: element.props.placeholder, required: element.props.required, name: element.props.name, style: {
                                width: '100%',
                                padding: '10px 15px',
                                border: '1px solid #d1d5db',
                                borderRadius: '4px',
                                fontSize: '16px'
                            } })] })), element.type === 'textarea' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("label", { style: { display: 'block', marginBottom: '5px', fontWeight: '500' }, children: element.props.label }), _jsx("textarea", { placeholder: element.props.placeholder, required: element.props.required, name: element.props.name, rows: element.props.rows || 4, style: {
                                width: '100%',
                                padding: '10px 15px',
                                border: '1px solid #d1d5db',
                                borderRadius: '4px',
                                fontSize: '16px',
                                resize: 'vertical'
                            } })] })), element.type === 'select' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("label", { style: { display: 'block', marginBottom: '5px', fontWeight: '500' }, children: element.props.label }), _jsx("select", { required: element.props.required, name: element.props.name, style: {
                                width: '100%',
                                padding: '10px 15px',
                                border: '1px solid #d1d5db',
                                borderRadius: '4px',
                                fontSize: '16px'
                            }, children: (element.props.options || []).map((option, index) => (_jsx("option", { value: option, children: option }, index))) })] })), element.type === 'checkbox' && (_jsxs("div", { style: { ...getEffectiveStyles(), display: 'flex', alignItems: 'center', gap: '10px' }, children: [_jsx("input", { type: "checkbox", required: element.props.required, name: element.props.name, style: { width: '18px', height: '18px' } }), _jsx("label", { style: { fontWeight: '400' }, children: element.props.label })] })), element.type === 'submit' && (_jsx("button", { type: "submit", style: getEffectiveStyles(), children: element.props.text })), element.type === 'carousel' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("div", { style: {
                            position: 'relative',
                            width: '100%',
                            height: '400px',
                            backgroundColor: '#f3f4f6',
                            borderRadius: '8px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            overflow: 'hidden'
                        }, children: element.props.images && element.props.images.length > 0 ? (_jsx("img", { src: element.props.images[0], alt: "Slide", style: { width: '100%', height: '100%', objectFit: 'cover' } })) : (_jsxs("div", { style: { textAlign: 'center', color: '#9ca3af' }, children: [_jsx(Play, { style: { fontSize: '48px', marginBottom: '10px' } }), _jsx("p", { children: "Add images to carousel" })] })) }) })), element.type === 'pricing-table' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("h3", { style: { fontSize: '24px', fontWeight: '600', marginBottom: '20px' }, children: element.props.title }), _jsxs("div", { style: { marginBottom: '30px' }, children: [_jsxs("span", { style: { fontSize: '48px', fontWeight: '700' }, children: [element.props.currency, element.props.price] }), _jsxs("span", { style: { fontSize: '18px', color: '#6b7280' }, children: ["/", element.props.period] })] }), _jsx("ul", { style: { textAlign: 'left', marginBottom: '30px', listStyle: 'none', padding: 0 }, children: (element.props.features || []).map((feature, index) => (_jsxs("li", { style: { padding: '10px 0', borderBottom: '1px solid #e5e7eb' }, children: ["\u2713 ", feature] }, index))) }), _jsx("button", { style: {
                                width: '100%',
                                padding: '15px',
                                backgroundColor: '#0066cc',
                                color: '#ffffff',
                                border: 'none',
                                borderRadius: '8px',
                                fontSize: '16px',
                                fontWeight: '600',
                                cursor: 'pointer'
                            }, children: element.props.buttonText })] })), element.type === 'google-maps' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("iframe", { width: "100%", height: element.props.height || '400px', style: { border: 0, borderRadius: '8px' }, loading: "lazy", allowFullScreen: true, src: `https://www.google.com/maps/embed/v1/place?key=YOUR_API_KEY&q=${encodeURIComponent(element.props.address || 'New York')}&zoom=${element.props.zoom || 14}` }) })), element.type === 'social-icons' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.icons || []).map((icon, index) => (_jsx("a", { href: icon.url, target: "_blank", rel: "noopener noreferrer", style: {
                            display: 'inline-flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            width: element.props.size || '40px',
                            height: element.props.size || '40px',
                            backgroundColor: '#3b5998',
                            borderRadius: '50%',
                            color: '#ffffff',
                            textDecoration: 'none'
                        }, children: _jsx(Share2, { style: { width: '20px', height: '20px' } }) }, index))) })), element.type === 'alert' && (_jsxs("div", { style: {
                        ...getEffectiveStyles(),
                        backgroundColor: element.props.type === 'success' ? '#d1fae5'
                            : element.props.type === 'warning' ? '#fef3c7'
                                : element.props.type === 'error' ? '#fee2e2'
                                    : '#dbeafe',
                        border: `1px solid ${element.props.type === 'success' ? '#10b981'
                            : element.props.type === 'warning' ? '#f59e0b'
                                : element.props.type === 'error' ? '#ef4444'
                                    : '#3b82f6'}`,
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '15px'
                    }, children: [_jsx(AlertCircle, { style: {
                                width: '24px',
                                height: '24px',
                                color: element.props.type === 'success' ? '#10b981'
                                    : element.props.type === 'warning' ? '#f59e0b'
                                        : element.props.type === 'error' ? '#ef4444'
                                            : '#3b82f6'
                            } }), _jsxs("div", { style: { flex: 1 }, children: [element.props.title && (_jsx("div", { style: { fontWeight: '600', marginBottom: '5px' }, children: element.props.title })), _jsx("div", { children: element.props.message })] })] })), element.type === 'timeline' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsxs("div", { style: {
                            display: 'flex',
                            gap: '20px',
                            marginBottom: '40px',
                            position: 'relative'
                        }, children: [_jsx("div", { style: {
                                    minWidth: '80px',
                                    fontWeight: '700',
                                    fontSize: '20px',
                                    color: '#0066cc'
                                }, children: item.year }), _jsxs("div", { style: {
                                    position: 'relative',
                                    paddingLeft: '30px',
                                    borderLeft: index < element.props.items.length - 1 ? '2px solid #e5e7eb' : 'none'
                                }, children: [_jsx("div", { style: {
                                            position: 'absolute',
                                            left: '-6px',
                                            top: '5px',
                                            width: '10px',
                                            height: '10px',
                                            backgroundColor: '#0066cc',
                                            borderRadius: '50%'
                                        } }), _jsx("h4", { style: { fontSize: '18px', fontWeight: '600', marginBottom: '10px' }, children: item.title }), _jsx("p", { style: { color: '#6b7280', lineHeight: '1.6' }, children: item.description })] })] }, index))) })), element.type === 'nav-menu' && (_jsx("nav", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsx("a", { href: item.url, style: { textDecoration: 'none', color: 'inherit', fontWeight: '500' }, children: item.label }, index))) })), element.type === 'breadcrumbs' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsxs("span", { children: [_jsx("a", { href: item.url, style: { textDecoration: 'none', color: 'inherit' }, children: item.label }), index < element.props.items.length - 1 && _jsx("span", { style: { margin: '0 8px' }, children: element.props.separator })] }, index))) })), element.type === 'search' && (_jsxs("form", { action: element.props.action, method: "GET", style: getEffectiveStyles(), children: [_jsx("input", { type: "text", name: "q", placeholder: element.props.placeholder, style: { flex: 1, padding: '10px 15px', border: '1px solid #d1d5db', borderRadius: '4px' } }), _jsx("button", { type: "submit", style: { padding: '10px 20px', backgroundColor: '#0066cc', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer' }, children: element.props.buttonText })] })), element.type === 'posts-grid' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("div", { style: { display: 'grid', gridTemplateColumns: `repeat(${element.props.columns}, 1fr)`, gap: '30px' }, children: [1, 2, 3].map(i => (_jsxs("div", { style: { border: '1px solid #e5e7eb', borderRadius: '8px', overflow: 'hidden' }, children: [_jsx("div", { style: { width: '100%', height: '200px', backgroundColor: '#e5e7eb' } }), _jsxs("div", { style: { padding: '20px' }, children: [_jsxs("h3", { style: { fontSize: '20px', fontWeight: '600', marginBottom: '10px' }, children: ["Post Title ", i] }), element.props.showExcerpt && _jsx("p", { style: { color: '#6b7280', marginBottom: '10px' }, children: "Post excerpt goes here..." }), element.props.showDate && _jsx("span", { style: { fontSize: '14px', color: '#9ca3af' }, children: "January 1, 2025" })] })] }, i))) }) })), element.type === 'animated-headline' && (_jsxs("div", { style: getEffectiveStyles(), children: [element.props.beforeText, " ", _jsx("span", { style: { color: '#0066cc' }, children: element.props.animatedWords[0] }), " ", element.props.afterText] })), element.type === 'flip-box' && (_jsx("div", { style: getEffectiveStyles(), children: _jsxs("div", { style: { border: '2px solid #e5e7eb', borderRadius: '8px', padding: '40px', textAlign: 'center' }, children: [_jsx("h3", { style: { fontSize: '24px', fontWeight: '600', marginBottom: '10px' }, children: element.props.frontTitle }), _jsx("p", { style: { color: '#6b7280' }, children: element.props.frontContent })] }) })), element.type === 'countdown' && (_jsxs("div", { style: getEffectiveStyles(), children: [element.props.showDays && _jsxs("div", { style: { textAlign: 'center' }, children: [_jsx("div", { style: { fontSize: '40px', fontWeight: '700' }, children: "00" }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: "Days" })] }), element.props.showHours && _jsxs("div", { style: { textAlign: 'center' }, children: [_jsx("div", { style: { fontSize: '40px', fontWeight: '700' }, children: "00" }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: "Hours" })] }), element.props.showMinutes && _jsxs("div", { style: { textAlign: 'center' }, children: [_jsx("div", { style: { fontSize: '40px', fontWeight: '700' }, children: "00" }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: "Minutes" })] }), element.props.showSeconds && _jsxs("div", { style: { textAlign: 'center' }, children: [_jsx("div", { style: { fontSize: '40px', fontWeight: '700' }, children: "00" }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: "Seconds" })] })] })), element.type === 'hotspot' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("div", { style: { width: '100%', height: '400px', backgroundColor: '#e5e7eb', position: 'relative', borderRadius: '8px' }, children: (element.props.hotspots || []).map((spot, index) => (_jsx("div", { style: {
                                position: 'absolute',
                                left: `${spot.x}%`,
                                top: `${spot.y}%`,
                                width: '30px',
                                height: '30px',
                                backgroundColor: '#0066cc',
                                borderRadius: '50%',
                                border: '3px solid white',
                                cursor: 'pointer'
                            }, title: spot.tooltip }, index))) }) })), element.type === 'price-menu' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsxs("div", { style: { display: 'flex', gap: '20px', padding: '20px', borderBottom: '1px solid #e5e7eb' }, children: [_jsx("div", { style: { width: '80px', height: '80px', backgroundColor: '#e5e7eb', borderRadius: '8px', flexShrink: 0 } }), _jsxs("div", { style: { flex: 1 }, children: [_jsx("h4", { style: { fontSize: '18px', fontWeight: '600', marginBottom: '5px' }, children: item.name }), _jsx("p", { style: { fontSize: '14px', color: '#6b7280' }, children: item.description })] }), _jsxs("div", { style: { fontSize: '20px', fontWeight: '700', color: '#0066cc' }, children: ["$", item.price] })] }, index))) })), element.type === 'table' && (_jsxs("table", { style: getEffectiveStyles(), children: [_jsx("thead", { children: _jsx("tr", { children: (element.props.headers || []).map((header, i) => (_jsx("th", { style: { padding: '15px', textAlign: 'left', borderBottom: '2px solid #e5e7eb', fontWeight: '600' }, children: header }, i))) }) }), _jsx("tbody", { children: (element.props.rows || []).map((row, i) => (_jsx("tr", { style: { backgroundColor: element.props.striped && i % 2 === 1 ? '#f9fafb' : 'transparent' }, children: row.map((cell, j) => (_jsx("td", { style: { padding: '15px', borderBottom: '1px solid #e5e7eb' }, children: cell }, j))) }, i))) })] })), element.type === 'modal-popup' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("button", { style: { padding: '12px 24px', backgroundColor: '#0066cc', color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer' }, children: element.props.triggerText }) })), element.type === 'login' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("h3", { style: { fontSize: '24px', fontWeight: '600', marginBottom: '20px' }, children: "Login" }), _jsxs("form", { style: { display: 'flex', flexDirection: 'column', gap: '15px' }, children: [_jsx("input", { type: "email", placeholder: "Email", style: { padding: '10px 15px', border: '1px solid #d1d5db', borderRadius: '4px' } }), _jsx("input", { type: "password", placeholder: "Password", style: { padding: '10px 15px', border: '1px solid #d1d5db', borderRadius: '4px' } }), _jsx("button", { type: "submit", style: { padding: '12px', backgroundColor: '#0066cc', color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer' }, children: "Login" }), element.props.showForgotPassword && _jsx("a", { href: "#", style: { fontSize: '14px', color: '#0066cc', textAlign: 'center' }, children: "Forgot Password?" }), element.props.showRegisterLink && _jsx("a", { href: "#", style: { fontSize: '14px', color: '#0066cc', textAlign: 'center' }, children: "Create Account" })] })] })), element.type === 'share-buttons' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.networks || []).map((network, index) => (_jsx("a", { href: "#", style: {
                            display: element.props.showLabels ? 'flex' : 'inline-flex',
                            alignItems: 'center',
                            gap: '8px',
                            padding: '10px 15px',
                            backgroundColor: '#e5e7eb',
                            borderRadius: element.props.style === 'rounded' ? '50px' : '4px',
                            textDecoration: 'none',
                            color: '#374151',
                            fontWeight: '500'
                        }, children: network }, index))) })), element.type === 'call-to-action' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("h2", { style: { fontSize: '36px', fontWeight: '700', marginBottom: '15px' }, children: element.props.title }), _jsx("p", { style: { fontSize: '18px', marginBottom: '30px', opacity: 0.9 }, children: element.props.description }), _jsx("a", { href: element.props.buttonUrl, style: {
                                display: 'inline-block',
                                padding: '15px 40px',
                                backgroundColor: '#ffffff',
                                color: '#0066cc',
                                borderRadius: '8px',
                                textDecoration: 'none',
                                fontWeight: '600',
                                fontSize: '16px'
                            }, children: element.props.buttonText })] })), element.type === 'faq' && (_jsx("div", { style: getEffectiveStyles(), children: (element.props.items || []).map((item, index) => (_jsxs("div", { style: { padding: '20px', border: '1px solid #e5e7eb', borderRadius: '8px', marginBottom: '10px' }, children: [_jsxs("h4", { style: { fontSize: '18px', fontWeight: '600', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '10px' }, children: [_jsx("span", { style: { fontSize: '14px', color: '#6b7280' }, children: "\u25BC" }), item.question] }), _jsx("p", { style: { color: '#6b7280', lineHeight: '1.6' }, children: item.answer })] }, index))) })), element.type === 'contact-form' && (_jsxs("form", { style: getEffectiveStyles(), children: [element.props.fields.includes('name') && _jsx("input", { type: "text", name: "name", placeholder: "Your Name", style: { padding: '12px 15px', border: '1px solid #d1d5db', borderRadius: '4px', width: '100%' } }), element.props.fields.includes('email') && _jsx("input", { type: "email", name: "email", placeholder: "Your Email", style: { padding: '12px 15px', border: '1px solid #d1d5db', borderRadius: '4px', width: '100%' } }), element.props.fields.includes('subject') && _jsx("input", { type: "text", name: "subject", placeholder: "Subject", style: { padding: '12px 15px', border: '1px solid #d1d5db', borderRadius: '4px', width: '100%' } }), element.props.fields.includes('message') && _jsx("textarea", { name: "message", placeholder: "Your Message", rows: 5, style: { padding: '12px 15px', border: '1px solid #d1d5db', borderRadius: '4px', width: '100%', resize: 'vertical' } }), _jsx("button", { type: "submit", style: { padding: '12px 30px', backgroundColor: '#0066cc', color: '#fff', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: '600' }, children: element.props.submitText })] })), element.type === 'team-member' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("div", { style: { width: '150px', height: '150px', backgroundColor: '#e5e7eb', borderRadius: '50%', margin: '0 auto 20px' } }), _jsx("h3", { style: { fontSize: '22px', fontWeight: '600', marginBottom: '5px' }, children: element.props.name }), _jsx("p", { style: { fontSize: '16px', color: '#6b7280', marginBottom: '15px' }, children: element.props.position }), _jsx("p", { style: { fontSize: '14px', color: '#6b7280', lineHeight: '1.6', marginBottom: '20px' }, children: element.props.bio }), _jsxs("div", { style: { display: 'flex', gap: '15px', justifyContent: 'center' }, children: [element.props.social?.linkedin && _jsx("a", { href: element.props.social.linkedin, style: { color: '#0066cc' }, children: "LinkedIn" }), element.props.social?.twitter && _jsx("a", { href: element.props.social.twitter, style: { color: '#0066cc' }, children: "Twitter" }), element.props.social?.email && _jsx("a", { href: `mailto:${element.props.social.email}`, style: { color: '#0066cc' }, children: "Email" })] })] })), element.type === 'image-comparison' && (_jsx("div", { style: getEffectiveStyles(), children: _jsx("div", { style: { position: 'relative', width: '100%', height: '400px', backgroundColor: '#e5e7eb', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }, children: _jsxs("div", { style: { textAlign: 'center' }, children: [_jsxs("div", { style: { fontSize: '18px', fontWeight: '600' }, children: [element.props.beforeLabel, " / ", element.props.afterLabel] }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280', marginTop: '10px' }, children: "Drag slider to compare" })] }) }) })), element.type === 'coupon' && (_jsxs("div", { style: getEffectiveStyles(), children: [_jsx("div", { style: { fontSize: '14px', color: '#6b7280', marginBottom: '10px' }, children: "USE CODE" }), _jsx("div", { style: { fontSize: '36px', fontWeight: '700', marginBottom: '10px', letterSpacing: '2px' }, children: element.props.code }), _jsx("div", { style: { fontSize: '24px', color: '#0066cc', fontWeight: '600', marginBottom: '15px' }, children: element.props.discount }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280', marginBottom: '5px' }, children: element.props.description }), _jsxs("div", { style: { fontSize: '12px', color: '#9ca3af' }, children: ["Expires: ", element.props.expiry] })] })), element.type === 'audio-player' && (_jsx("div", { style: getEffectiveStyles(), children: _jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: '20px', padding: '20px', backgroundColor: '#f9fafb', borderRadius: '8px' }, children: [_jsx("button", { style: { width: '60px', height: '60px', borderRadius: '50%', backgroundColor: '#0066cc', color: '#fff', border: 'none', fontSize: '20px', cursor: 'pointer' }, children: "\u25B6" }), _jsxs("div", { style: { flex: 1 }, children: [_jsx("div", { style: { fontSize: '18px', fontWeight: '600', marginBottom: '5px' }, children: element.props.title }), _jsx("div", { style: { fontSize: '14px', color: '#6b7280' }, children: element.props.artist })] })] }) })), element.type === 'widget' && (_jsxs("div", { className: "p-4 border-2 border-dashed border-gray-300 rounded", children: ["Widget: ", element.props.widgetId] }))] }, element.id));
    };
    // CSS class helpers - STRONG VISIBLE CONTRAST
    // NOTTE: Sfondo grigio scuro visibile (#1f2937 = neutral-800), testo bianco
    // GIORNO: Sfondo bianco/grigio chiaro, testo NERO
    const inputClass = canvasMode === 'dark'
        ? 'bg-neutral-800 border-neutral-600 text-white placeholder:text-neutral-500 focus:border-neutral-500 focus:ring-1 focus:ring-neutral-500'
        : 'bg-gray-50 border-gray-300 text-black placeholder:text-gray-500 focus:border-gray-400 focus:ring-1 focus:ring-gray-400';
    const selectClass = canvasMode === 'dark'
        ? 'bg-neutral-800 border-neutral-600 text-white focus:border-neutral-500 focus:ring-1 focus:ring-neutral-500'
        : 'bg-gray-50 border-gray-300 text-black focus:border-gray-400 focus:ring-1 focus:ring-gray-400';
    const labelClass = canvasMode === 'dark'
        ? 'text-neutral-300'
        : 'text-gray-900';
    const headingClass = canvasMode === 'dark'
        ? 'text-white'
        : 'text-gray-900';
    const borderClass = canvasMode === 'dark'
        ? 'border-neutral-700'
        : 'border-gray-200';
    return (_jsxs("div", { className: `flex h-screen ${canvasMode === 'dark' ? 'bg-neutral-900' : 'bg-neutral-50'}`, children: [!state.previewMode && (_jsxs("div", { className: `w-80 overflow-y-auto ${canvasMode === 'dark'
                    ? 'bg-neutral-800 border-r border-neutral-700'
                    : 'bg-white border-r border-neutral-200'}`, children: [_jsxs("div", { className: `flex ${canvasMode === 'dark' ? 'border-b border-neutral-700' : 'border-b border-neutral-200'}`, children: [_jsx("button", { onClick: () => setLeftPanelTab('elements'), className: `flex-1 px-4 py-3 text-sm font-medium ${leftPanelTab === 'elements'
                                    ? 'text-blue-500 border-b-2 border-blue-500'
                                    : canvasMode === 'dark'
                                        ? 'text-neutral-400 hover:text-neutral-200'
                                        : 'text-neutral-600 hover:text-neutral-900'}`, children: "Elements" }), _jsx("button", { onClick: () => setLeftPanelTab('widgets'), className: `flex-1 px-4 py-3 text-sm font-medium ${leftPanelTab === 'widgets'
                                    ? 'text-blue-500 border-b-2 border-blue-500'
                                    : canvasMode === 'dark'
                                        ? 'text-neutral-400 hover:text-neutral-200'
                                        : 'text-neutral-600 hover:text-neutral-900'}`, children: "Widgets" })] }), leftPanelTab === 'elements' && (_jsx("div", { className: "p-4", children: _jsx("div", { className: "grid grid-cols-3 gap-2", children: defaultElements.map(element => {
                                // Determine parent based on element type and selected element
                                const getParentId = () => {
                                    if (element.type === 'section')
                                        return undefined; // Sections always go to root
                                    if (element.type === 'column' && state.selectedElementId) {
                                        // Columns go into selected section (if it's a section)
                                        const selectedEl = findElement(page.elements, state.selectedElementId);
                                        if (selectedEl?.type === 'section')
                                            return state.selectedElementId;
                                    }
                                    if (element.type !== 'column' && state.selectedElementId) {
                                        // Other elements go into selected container
                                        return state.selectedElementId;
                                    }
                                    return undefined;
                                };
                                // Check if column button should be disabled
                                const isColumnDisabled = element.type === 'column' && (!state.selectedElementId || (() => {
                                    const selectedEl = findElement(page.elements, state.selectedElementId);
                                    return selectedEl?.type !== 'section';
                                })());
                                // Get icon component
                                const getIcon = () => {
                                    switch (element.type) {
                                        case 'section': return Layout;
                                        case 'column': return Grid;
                                        case 'heading': return Type;
                                        case 'text': return Type;
                                        case 'button': return Square;
                                        case 'image': return ImageIcon;
                                        case 'video': return Video;
                                        case 'spacer': return Circle;
                                        case 'divider': return Square;
                                        case 'icon': return Star;
                                        case 'icon-box': return Square;
                                        case 'star-rating': return Star;
                                        case 'progress-bar': return BarChart3;
                                        case 'counter': return Hash;
                                        case 'testimonial': return MessageSquare;
                                        case 'accordion': return ChevronDown;
                                        case 'tabs': return Layers;
                                        case 'toggle': return AlignJustify;
                                        case 'list': return List;
                                        case 'form': return FileText;
                                        case 'input': return Type;
                                        case 'textarea': return AlignJustify;
                                        case 'select': return ChevronDown;
                                        case 'checkbox': return CheckSquare;
                                        case 'submit': return Send;
                                        case 'carousel': return Play;
                                        case 'pricing-table': return DollarSign;
                                        case 'google-maps': return MapPin;
                                        case 'social-icons': return Share2;
                                        case 'alert': return AlertCircle;
                                        case 'timeline': return Clock;
                                        case 'nav-menu': return Menu;
                                        case 'breadcrumbs': return ChevronRight;
                                        case 'search': return Search;
                                        case 'posts-grid': return Grid;
                                        case 'animated-headline': return Zap;
                                        case 'flip-box': return Square;
                                        case 'countdown': return Calendar;
                                        case 'hotspot': return MapPin;
                                        case 'price-menu': return DollarSign;
                                        case 'table': return Table2;
                                        case 'modal-popup': return Square;
                                        case 'login': return Users;
                                        case 'share-buttons': return Share2;
                                        case 'call-to-action': return Zap;
                                        case 'faq': return BookOpen;
                                        case 'contact-form': return Mail;
                                        case 'team-member': return Users;
                                        case 'image-comparison': return Circle;
                                        case 'coupon': return Percent;
                                        case 'audio-player': return Play;
                                        default: return Layout;
                                    }
                                };
                                const Icon = getIcon();
                                return (_jsxs("button", { onClick: () => {
                                        if (isColumnDisabled) {
                                            alert('Please select a Section first before adding a Column');
                                            return;
                                        }
                                        addElement(element.type, getParentId());
                                    }, disabled: isColumnDisabled, className: `flex flex-col items-center gap-2 p-3 rounded-lg transition-all ${isColumnDisabled
                                        ? 'opacity-50 cursor-not-allowed'
                                        : canvasMode === 'dark'
                                            ? 'hover:bg-neutral-700 hover:border-neutral-500'
                                            : 'hover:bg-gray-100 hover:border-gray-400'} border-2 ${canvasMode === 'dark' ? 'border-neutral-700' : 'border-gray-300'}`, children: [_jsx("div", { className: `w-12 h-12 flex items-center justify-center rounded-lg ${canvasMode === 'dark'
                                                ? 'bg-neutral-700 text-neutral-300'
                                                : 'bg-gray-200 text-gray-700'}`, children: _jsx(Icon, { className: "w-6 h-6" }) }), _jsx("span", { className: `text-xs font-medium text-center leading-tight ${canvasMode === 'dark' ? 'text-neutral-200' : 'text-gray-900'}`, children: element.label })] }, element.type));
                            }) }) })), leftPanelTab === 'widgets' && (_jsx("div", { className: "p-4", children: availableWidgets.length === 0 ? (_jsxs("div", { className: `text-center py-8 ${canvasMode === 'dark' ? 'text-neutral-400' : 'text-neutral-500'}`, children: [_jsx(Grid, { className: "w-12 h-12 mx-auto mb-3 opacity-50" }), _jsx("p", { className: "text-sm", children: "No widgets available" }), _jsx("p", { className: "text-xs mt-1", children: "Widgets will appear here when configured" })] })) : (_jsx("div", { className: "grid grid-cols-3 gap-2", children: availableWidgets.map(widget => (_jsxs("button", { onClick: () => addElement('widget'), className: `flex flex-col items-center gap-2 p-3 rounded-lg transition-all ${canvasMode === 'dark'
                                    ? 'hover:bg-neutral-700 hover:border-neutral-500'
                                    : 'hover:bg-gray-100 hover:border-gray-400'} border-2 ${canvasMode === 'dark' ? 'border-neutral-700' : 'border-gray-300'}`, children: [_jsx("div", { className: `w-12 h-12 flex items-center justify-center rounded-lg ${canvasMode === 'dark'
                                            ? 'bg-neutral-700 text-neutral-300'
                                            : 'bg-gray-200 text-gray-700'}`, children: _jsx(Grid, { className: "w-6 h-6" }) }), _jsx("span", { className: `text-xs font-medium text-center leading-tight ${canvasMode === 'dark' ? 'text-neutral-200' : 'text-gray-900'}`, children: widget.label })] }, widget.type))) })) }))] })), _jsxs("div", { className: "flex-1 flex flex-col overflow-hidden", children: [_jsxs("div", { className: `h-16 flex items-center justify-between px-6 ${canvasMode === 'dark'
                            ? 'bg-neutral-800 border-b border-neutral-700'
                            : 'bg-white border-b border-neutral-200'}`, children: [_jsxs("div", { className: "flex items-center gap-2", children: [_jsx("button", { onClick: undo, disabled: state.historyIndex === 0, className: `p-2 rounded disabled:opacity-50 disabled:cursor-not-allowed ${canvasMode === 'dark'
                                            ? 'hover:bg-neutral-700 text-neutral-300'
                                            : 'hover:bg-neutral-100 text-neutral-700'}`, children: _jsx(Undo, { className: "w-5 h-5" }) }), _jsx("button", { onClick: redo, disabled: state.historyIndex === state.history.length - 1, className: `p-2 rounded disabled:opacity-50 disabled:cursor-not-allowed ${canvasMode === 'dark'
                                            ? 'hover:bg-neutral-700 text-neutral-300'
                                            : 'hover:bg-neutral-100 text-neutral-700'}`, children: _jsx(Redo, { className: "w-5 h-5" }) })] }), _jsxs("div", { className: "flex items-center gap-2", children: [_jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'desktop' })), className: `p-2 rounded ${state.viewportMode === 'desktop'
                                            ? 'bg-blue-500 text-white'
                                            : canvasMode === 'dark'
                                                ? 'hover:bg-neutral-700 text-neutral-300'
                                                : 'hover:bg-neutral-100 text-neutral-700'}`, title: "Desktop", children: _jsx(Monitor, { className: "w-5 h-5" }) }), _jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'tablet' })), className: `p-2 rounded ${state.viewportMode === 'tablet'
                                            ? 'bg-blue-500 text-white'
                                            : canvasMode === 'dark'
                                                ? 'hover:bg-neutral-700 text-neutral-300'
                                                : 'hover:bg-neutral-100 text-neutral-700'}`, title: "Tablet", children: _jsx(Tablet, { className: "w-5 h-5" }) }), _jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'mobile' })), className: `p-2 rounded ${state.viewportMode === 'mobile'
                                            ? 'bg-blue-500 text-white'
                                            : canvasMode === 'dark'
                                                ? 'hover:bg-neutral-700 text-neutral-300'
                                                : 'hover:bg-neutral-100 text-neutral-700'}`, title: "Mobile", children: _jsx(Smartphone, { className: "w-5 h-5" }) }), state.viewportMode === 'mobile' && (_jsx("select", { value: mobileResolution, onChange: (e) => setMobileResolution(e.target.value), className: `px-2 py-1 text-sm rounded border ${canvasMode === 'dark'
                                            ? 'bg-neutral-700 border-neutral-600 text-neutral-200'
                                            : 'bg-white border-neutral-300 text-neutral-700'}`, children: Object.entries(mobileResolutions).map(([key, value]) => (_jsx("option", { value: key, children: value.label }, key))) })), _jsx("div", { className: `w-px h-6 mx-1 ${canvasMode === 'dark' ? 'bg-neutral-600' : 'bg-neutral-300'}` }), _jsx("button", { onClick: () => setCanvasMode(prev => prev === 'light' ? 'dark' : 'light'), className: `p-2 px-3 rounded font-medium ${canvasMode === 'dark'
                                            ? 'bg-yellow-500/20 text-yellow-400 hover:bg-yellow-500/30'
                                            : 'bg-neutral-200 text-neutral-700 hover:bg-neutral-300'}`, title: canvasMode === 'light' ? 'Switch to Dark Mode' : 'Switch to Light Mode', children: canvasMode === 'light' ? '🌙 Dark' : '☀️ Light' })] }), _jsxs("div", { className: "flex items-center gap-2", children: [_jsx("button", { onClick: () => {
                                            setShowPageSettings(!showPageSettings);
                                            setState(prev => ({ ...prev, selectedElementId: null }));
                                        }, className: `px-4 py-2 text-sm font-medium rounded ${showPageSettings
                                            ? 'bg-blue-500 text-white'
                                            : canvasMode === 'dark'
                                                ? 'text-neutral-300 hover:bg-neutral-700'
                                                : 'text-neutral-700 hover:bg-neutral-100'}`, title: "Page Settings", children: _jsx(Settings, { className: "w-5 h-5" }) }), _jsx("button", { onClick: () => {
                                            setShowDeviceManager(!showDeviceManager);
                                            if (!showDeviceManager) {
                                                loadAllDevices();
                                            }
                                        }, className: `px-4 py-2 text-sm font-medium rounded ${showDeviceManager
                                            ? 'bg-green-500 text-white'
                                            : canvasMode === 'dark'
                                                ? 'text-neutral-300 hover:bg-neutral-700'
                                                : 'text-neutral-700 hover:bg-neutral-100'}`, title: "Device Resolutions Manager", children: _jsx(Smartphone, { className: "w-5 h-5" }) }), _jsx("button", { onClick: () => setState(prev => ({ ...prev, previewMode: !prev.previewMode })), className: `px-4 py-2 text-sm font-medium rounded ${canvasMode === 'dark'
                                            ? 'text-neutral-300 hover:bg-neutral-700'
                                            : 'text-neutral-700 hover:bg-neutral-100'}`, children: state.previewMode ? _jsx(EyeOff, { className: "w-5 h-5" }) : _jsx(Eye, { className: "w-5 h-5" }) }), _jsx("button", { onClick: handleSave, disabled: isSaving, className: "px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded disabled:opacity-50", children: isSaving ? 'Saving...' : 'Save' }), onPublish && (_jsx("button", { onClick: () => onPublish(page), className: "px-4 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded", children: "Publish" }))] })] }), _jsx("div", { className: `flex-1 overflow-y-auto p-8 ${canvasMode === 'dark' ? 'bg-neutral-800' : 'bg-neutral-100'}`, style: canvasMode === 'light' ? {
                            backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 19px, #e5e7eb 19px, #e5e7eb 20px), repeating-linear-gradient(90deg, transparent, transparent 19px, #e5e7eb 19px, #e5e7eb 20px)',
                            backgroundSize: '20px 20px'
                        } : {
                            backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 19px, #374151 19px, #374151 20px), repeating-linear-gradient(90deg, transparent, transparent 19px, #374151 19px, #374151 20px)',
                            backgroundSize: '20px 20px'
                        }, children: _jsx("div", { className: `shadow-2xl min-h-screen mx-auto ${canvasMode === 'dark' ? 'bg-neutral-900' : 'bg-white'} ${state.viewportMode === 'tablet'
                                ? 'max-w-3xl'
                                : state.viewportMode === 'desktop'
                                    ? 'w-full'
                                    : ''}`, style: state.viewportMode === 'mobile' ? { width: mobileResolutions[mobileResolution].width, maxWidth: '100%' } : undefined, onClick: () => setState(prev => ({ ...prev, selectedElementId: null })), children: !page.elements || page.elements.length === 0 ? (_jsx("div", { className: "flex items-center justify-center h-96 text-neutral-400", children: _jsxs("div", { className: "text-center", children: [_jsx(Layout, { className: "w-16 h-16 mx-auto mb-4 opacity-50" }), _jsx("p", { className: "text-lg font-medium", children: "Start building your page" }), _jsx("p", { className: "text-sm", children: "Drag elements from the left panel" })] }) })) : (page.elements.map(element => renderElement(element))) }) })] }), !state.previewMode && (showPageSettings || state.selectedElementId) && (() => {
                // Show Page Settings
                if (showPageSettings) {
                    return (_jsxs("div", { className: `w-80 overflow-y-auto ${canvasMode === 'dark'
                            ? 'bg-neutral-800 border-l border-neutral-700'
                            : 'bg-white border-l border-neutral-200'}`, children: [_jsx("div", { className: `p-4 ${canvasMode === 'dark' ? 'border-b border-neutral-700' : 'border-b border-neutral-200'}`, children: _jsxs("h3", { className: `text-lg font-semibold flex items-center gap-2 ${canvasMode === 'dark' ? 'text-neutral-100' : 'text-neutral-900'}`, children: [_jsx(Settings, { className: "w-5 h-5" }), "Page Settings"] }) }), _jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Page Info" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Title" }), _jsx("input", { type: "text", value: page.title, onChange: (e) => setPage(prev => ({ ...prev, title: e.target.value })), className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Slug" }), _jsx("input", { type: "text", value: page.slug, onChange: (e) => setPage(prev => ({ ...prev, slug: e.target.value })), className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Layout" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Layout Type" }), _jsxs("select", { value: page.settings.layout, onChange: (e) => setPage(prev => ({
                                            ...prev,
                                            settings: { ...prev.settings, layout: e.target.value }
                                        })), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "full-width", children: "Full Width" }), _jsx("option", { value: "boxed", children: "Boxed" })] }), page.settings.layout === 'boxed' && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Max Width" }), _jsx("input", { type: "text", value: page.settings.maxWidth || '', onChange: (e) => setPage(prev => ({
                                                    ...prev,
                                                    settings: { ...prev.settings, maxWidth: e.target.value }
                                                })), placeholder: "1200px", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }))] }), _jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Background" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Color" }), _jsx("input", { type: "color", value: page.settings.backgroundColor || '#ffffff', onChange: (e) => setPage(prev => ({
                                            ...prev,
                                            settings: { ...prev.settings, backgroundColor: e.target.value }
                                        })), className: `w-full h-10 border rounded ${inputClass}` })] }), _jsxs("div", { className: "p-4", children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Custom Code" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Custom CSS" }), _jsx("textarea", { value: page.settings.customCSS || '', onChange: (e) => setPage(prev => ({
                                            ...prev,
                                            settings: { ...prev.settings, customCSS: e.target.value }
                                        })), rows: 4, className: `w-full px-3 py-2 border rounded mb-3 font-mono text-sm ${inputClass}`, placeholder: ".my-class { color: red; }" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Custom JS" }), _jsx("textarea", { value: page.settings.customJS || '', onChange: (e) => setPage(prev => ({
                                            ...prev,
                                            settings: { ...prev.settings, customJS: e.target.value }
                                        })), rows: 4, className: `w-full px-3 py-2 border rounded font-mono text-sm ${inputClass}`, placeholder: "console.log('Hello');" })] })] }));
                }
                // Show Element Properties
                if (!state.selectedElementId)
                    return null;
                const selectedElement = findElement(page.elements, state.selectedElementId);
                if (!selectedElement)
                    return null;
                return (_jsxs("div", { className: `w-80 overflow-y-auto ${canvasMode === 'dark'
                        ? 'bg-neutral-800 border-l border-neutral-700'
                        : 'bg-white border-l border-neutral-200'}`, children: [_jsxs("div", { className: `p-4 border-b ${borderClass}`, children: [_jsxs("h3", { className: `text-lg font-semibold flex items-center gap-2 mb-4 ${headingClass}`, children: [_jsx(Settings, { className: "w-5 h-5" }), selectedElement.type.charAt(0).toUpperCase() + selectedElement.type.slice(1), " Settings"] }), _jsxs("div", { className: "flex gap-1", children: [_jsx("button", { onClick: () => setRightPanelTab('content'), className: `flex-1 px-4 py-2 text-sm font-medium rounded-t transition-colors ${rightPanelTab === 'content'
                                                ? canvasMode === 'dark'
                                                    ? 'bg-neutral-700 text-white'
                                                    : 'bg-gray-200 text-gray-900'
                                                : canvasMode === 'dark'
                                                    ? 'bg-neutral-900 text-neutral-400 hover:bg-neutral-700 hover:text-neutral-200'
                                                    : 'bg-gray-50 text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`, children: "Content" }), _jsx("button", { onClick: () => setRightPanelTab('style'), className: `flex-1 px-4 py-2 text-sm font-medium rounded-t transition-colors ${rightPanelTab === 'style'
                                                ? canvasMode === 'dark'
                                                    ? 'bg-neutral-700 text-white'
                                                    : 'bg-gray-200 text-gray-900'
                                                : canvasMode === 'dark'
                                                    ? 'bg-neutral-900 text-neutral-400 hover:bg-neutral-700 hover:text-neutral-200'
                                                    : 'bg-gray-50 text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`, children: "Style" }), _jsx("button", { onClick: () => setRightPanelTab('advanced'), className: `flex-1 px-4 py-2 text-sm font-medium rounded-t transition-colors ${rightPanelTab === 'advanced'
                                                ? canvasMode === 'dark'
                                                    ? 'bg-neutral-700 text-white'
                                                    : 'bg-gray-200 text-gray-900'
                                                : canvasMode === 'dark'
                                                    ? 'bg-neutral-900 text-neutral-400 hover:bg-neutral-700 hover:text-neutral-200'
                                                    : 'bg-gray-50 text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`, children: "Advanced" })] })] }), rightPanelTab === 'content' && (_jsx("div", { children: (selectedElement.type === 'heading' || selectedElement.type === 'text' || selectedElement.type === 'button') && (_jsxs("div", { className: `p-4 border-b ${borderClass}`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Content" }), selectedElement.type === 'heading' && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Text" }), _jsx("input", { type: "text", value: selectedElement.props.text || '', onChange: (e) => updateElement(selectedElement.id, {
                                                    props: { ...selectedElement.props, text: e.target.value }
                                                }), className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Tag" }), _jsxs("select", { value: selectedElement.props.tag || 'h2', onChange: (e) => updateElement(selectedElement.id, {
                                                    props: { ...selectedElement.props, tag: e.target.value }
                                                }), className: `w-full px-3 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "h1", children: "H1" }), _jsx("option", { value: "h2", children: "H2" }), _jsx("option", { value: "h3", children: "H3" }), _jsx("option", { value: "h4", children: "H4" }), _jsx("option", { value: "h5", children: "H5" }), _jsx("option", { value: "h6", children: "H6" })] })] })), selectedElement.type === 'text' && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Content" }), _jsx("textarea", { value: selectedElement.props.content || '', onChange: (e) => updateElement(selectedElement.id, {
                                                    props: { ...selectedElement.props, content: e.target.value }
                                                }), rows: 4, className: `w-full px-3 py-2 border rounded ${inputClass}` })] })), selectedElement.type === 'button' && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Text" }), _jsx("input", { type: "text", value: selectedElement.props.text || '', onChange: (e) => updateElement(selectedElement.id, {
                                                    props: { ...selectedElement.props, text: e.target.value }
                                                }), className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Link" }), _jsx("input", { type: "text", value: selectedElement.props.link || '', onChange: (e) => updateElement(selectedElement.id, {
                                                    props: { ...selectedElement.props, link: e.target.value }
                                                }), className: `w-full px-3 py-2 border rounded ${inputClass}` })] }))] })) })), rightPanelTab === 'style' && (_jsxs("div", { children: [(selectedElement.type === 'heading' || selectedElement.type === 'text' || selectedElement.type === 'button') && (_jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Typography" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Font Family" }), _jsxs("select", { value: selectedElement.styles?.fontFamily || 'inherit', onChange: (e) => updateElement(selectedElement.id, {
                                                styles: { ...selectedElement.styles, fontFamily: e.target.value }
                                            }), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "inherit", children: "Default" }), _jsx("option", { value: "Arial, sans-serif", children: "Arial" }), _jsx("option", { value: "'Helvetica Neue', Helvetica, sans-serif", children: "Helvetica" }), _jsx("option", { value: "'Times New Roman', Times, serif", children: "Times New Roman" }), _jsx("option", { value: "Georgia, serif", children: "Georgia" }), _jsx("option", { value: "'Courier New', Courier, monospace", children: "Courier New" }), _jsx("option", { value: "Verdana, sans-serif", children: "Verdana" }), _jsx("option", { value: "'Inter', sans-serif", children: "Inter" }), _jsx("option", { value: "'Roboto', sans-serif", children: "Roboto" }), _jsx("option", { value: "'Open Sans', sans-serif", children: "Open Sans" })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Font Size" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "number", value: parseInt(selectedElement.styles?.fontSize || '16') || 16, onChange: (e) => {
                                                        const unit = (selectedElement.styles?.fontSize || 'px').replace(/[0-9]/g, '') || 'px';
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, fontSize: e.target.value + unit }
                                                        });
                                                    }, className: `flex-1 px-3 py-2 border rounded ${inputClass}` }), _jsxs("select", { value: (selectedElement.styles?.fontSize || 'px').replace(/[0-9]/g, '') || 'px', onChange: (e) => {
                                                        const num = parseInt(selectedElement.styles?.fontSize || '16') || 16;
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, fontSize: num + e.target.value }
                                                        });
                                                    }, className: `w-20 px-2 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "px", children: "px" }), _jsx("option", { value: "em", children: "em" }), _jsx("option", { value: "rem", children: "rem" }), _jsx("option", { value: "%", children: "%" }), _jsx("option", { value: "vw", children: "vw" })] })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Font Weight" }), _jsxs("select", { value: selectedElement.styles?.fontWeight || '400', onChange: (e) => updateElement(selectedElement.id, {
                                                styles: { ...selectedElement.styles, fontWeight: e.target.value }
                                            }), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "300", children: "Light (300)" }), _jsx("option", { value: "400", children: "Normal (400)" }), _jsx("option", { value: "500", children: "Medium (500)" }), _jsx("option", { value: "600", children: "Semi Bold (600)" }), _jsx("option", { value: "700", children: "Bold (700)" }), _jsx("option", { value: "800", children: "Extra Bold (800)" }), _jsx("option", { value: "900", children: "Black (900)" })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Line Height" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "number", step: "0.1", value: parseFloat(selectedElement.styles?.lineHeight || '1.5') || 1.5, onChange: (e) => {
                                                        const unit = (selectedElement.styles?.lineHeight || '').replace(/[0-9.]/g, '') || '';
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, lineHeight: e.target.value + unit }
                                                        });
                                                    }, className: `flex-1 px-3 py-2 border rounded ${inputClass}` }), _jsxs("select", { value: (selectedElement.styles?.lineHeight || '').replace(/[0-9.]/g, '') || '', onChange: (e) => {
                                                        const num = parseFloat(selectedElement.styles?.lineHeight || '1.5') || 1.5;
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, lineHeight: num + e.target.value }
                                                        });
                                                    }, className: `w-20 px-2 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "", children: "none" }), _jsx("option", { value: "px", children: "px" }), _jsx("option", { value: "em", children: "em" }), _jsx("option", { value: "%", children: "%" })] })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Text Color" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "color", value: selectedElement.styles?.color || '#000000', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, color: e.target.value }
                                                    }), className: `w-16 h-10 border rounded ${inputClass}` }), _jsx("input", { type: "text", value: selectedElement.styles?.color || '#000000', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, color: e.target.value }
                                                    }), placeholder: "#000000", className: `flex-1 px-3 py-2 border rounded ${inputClass}` })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Text Align" }), _jsx("div", { className: "flex gap-2 mb-3", children: ['left', 'center', 'right', 'justify'].map(align => (_jsx("button", { onClick: () => updateElement(selectedElement.id, {
                                                    styles: { ...selectedElement.styles, textAlign: align }
                                                }), className: `flex-1 px-3 py-2 border rounded capitalize ${selectedElement.styles?.textAlign === align
                                                    ? canvasMode === 'dark'
                                                        ? 'bg-blue-600 text-white border-blue-600'
                                                        : 'bg-blue-500 text-white border-blue-500'
                                                    : canvasMode === 'dark'
                                                        ? 'border-neutral-600 text-neutral-300 hover:bg-neutral-700'
                                                        : 'border-gray-300 text-gray-700 hover:bg-gray-50'}`, children: align }, align))) }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Text Transform" }), _jsxs("select", { value: selectedElement.styles?.textTransform || 'none', onChange: (e) => updateElement(selectedElement.id, {
                                                styles: { ...selectedElement.styles, textTransform: e.target.value }
                                            }), className: `w-full px-3 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "none", children: "None" }), _jsx("option", { value: "uppercase", children: "UPPERCASE" }), _jsx("option", { value: "lowercase", children: "lowercase" }), _jsx("option", { value: "capitalize", children: "Capitalize" })] })] })), _jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Background" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Color" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "color", value: selectedElement.styles?.backgroundColor || '#ffffff', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, backgroundColor: e.target.value }
                                                    }), className: `w-16 h-10 border rounded ${inputClass}` }), _jsx("input", { type: "text", value: selectedElement.styles?.backgroundColor || '#ffffff', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, backgroundColor: e.target.value }
                                                    }), placeholder: "#ffffff", className: `flex-1 px-3 py-2 border rounded ${inputClass}` })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Image" }), _jsx("input", { type: "text", value: selectedElement.styles?.backgroundImage?.replace(/^url\(['"]?|['"]?\)$/g, '') || '', onChange: (e) => updateElement(selectedElement.id, {
                                                styles: { ...selectedElement.styles, backgroundImage: e.target.value ? `url('${e.target.value}')` : '' }
                                            }), placeholder: "https://example.com/image.jpg", className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), selectedElement.styles?.backgroundImage && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Size" }), _jsxs("select", { value: selectedElement.styles?.backgroundSize || 'cover', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, backgroundSize: e.target.value }
                                                    }), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "auto", children: "Auto" }), _jsx("option", { value: "cover", children: "Cover" }), _jsx("option", { value: "contain", children: "Contain" }), _jsx("option", { value: "100% 100%", children: "Stretch" })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Position" }), _jsxs("select", { value: selectedElement.styles?.backgroundPosition || 'center center', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, backgroundPosition: e.target.value }
                                                    }), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "center center", children: "Center Center" }), _jsx("option", { value: "center top", children: "Center Top" }), _jsx("option", { value: "center bottom", children: "Center Bottom" }), _jsx("option", { value: "left top", children: "Left Top" }), _jsx("option", { value: "left center", children: "Left Center" }), _jsx("option", { value: "left bottom", children: "Left Bottom" }), _jsx("option", { value: "right top", children: "Right Top" }), _jsx("option", { value: "right center", children: "Right Center" }), _jsx("option", { value: "right bottom", children: "Right Bottom" })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Background Repeat" }), _jsxs("select", { value: selectedElement.styles?.backgroundRepeat || 'no-repeat', onChange: (e) => updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, backgroundRepeat: e.target.value }
                                                    }), className: `w-full px-3 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "no-repeat", children: "No Repeat" }), _jsx("option", { value: "repeat", children: "Repeat" }), _jsx("option", { value: "repeat-x", children: "Repeat X" }), _jsx("option", { value: "repeat-y", children: "Repeat Y" })] })] }))] }), _jsxs("div", { className: `p-4 ${borderClass} border-b`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Border" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Border Type" }), _jsxs("select", { value: (selectedElement.styles?.border || '').includes('solid') ? 'solid' : (selectedElement.styles?.border || '').includes('dashed') ? 'dashed' : 'none', onChange: (e) => {
                                                if (e.target.value === 'none') {
                                                    updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, border: 'none' }
                                                    });
                                                }
                                                else {
                                                    const width = selectedElement.styles?.borderWidth || '1px';
                                                    const color = selectedElement.styles?.borderColor || '#000000';
                                                    updateElement(selectedElement.id, {
                                                        styles: { ...selectedElement.styles, border: `${width} ${e.target.value} ${color}` }
                                                    });
                                                }
                                            }, className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "none", children: "None" }), _jsx("option", { value: "solid", children: "Solid" }), _jsx("option", { value: "dashed", children: "Dashed" }), _jsx("option", { value: "dotted", children: "Dotted" }), _jsx("option", { value: "double", children: "Double" })] }), selectedElement.styles?.border && selectedElement.styles?.border !== 'none' && (_jsxs(_Fragment, { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Border Width" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "number", value: parseInt((selectedElement.styles?.border || '1px').split(' ')[0]) || 1, onChange: (e) => {
                                                                const parts = (selectedElement.styles?.border || '1px solid #000000').split(' ');
                                                                parts[0] = e.target.value + 'px';
                                                                updateElement(selectedElement.id, {
                                                                    styles: { ...selectedElement.styles, border: parts.join(' '), borderWidth: e.target.value + 'px' }
                                                                });
                                                            }, className: `flex-1 px-3 py-2 border rounded ${inputClass}` }), _jsx("select", { value: "px", className: `w-20 px-2 py-2 border rounded ${selectClass}`, children: _jsx("option", { value: "px", children: "px" }) })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Border Color" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "color", value: (selectedElement.styles?.border || '').split(' ')[2] || '#000000', onChange: (e) => {
                                                                const parts = (selectedElement.styles?.border || '1px solid #000000').split(' ');
                                                                parts[2] = e.target.value;
                                                                updateElement(selectedElement.id, {
                                                                    styles: { ...selectedElement.styles, border: parts.join(' '), borderColor: e.target.value }
                                                                });
                                                            }, className: `w-16 h-10 border rounded ${inputClass}` }), _jsx("input", { type: "text", value: (selectedElement.styles?.border || '').split(' ')[2] || '#000000', onChange: (e) => {
                                                                const parts = (selectedElement.styles?.border || '1px solid #000000').split(' ');
                                                                parts[2] = e.target.value;
                                                                updateElement(selectedElement.id, {
                                                                    styles: { ...selectedElement.styles, border: parts.join(' '), borderColor: e.target.value }
                                                                });
                                                            }, placeholder: "#000000", className: `flex-1 px-3 py-2 border rounded ${inputClass}` })] })] })), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Border Radius" }), _jsxs("div", { className: "flex gap-2 mb-3", children: [_jsx("input", { type: "number", value: parseInt(selectedElement.styles?.borderRadius || '0') || 0, onChange: (e) => {
                                                        const unit = (selectedElement.styles?.borderRadius || 'px').replace(/[0-9]/g, '') || 'px';
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, borderRadius: e.target.value + unit }
                                                        });
                                                    }, className: `flex-1 px-3 py-2 border rounded ${inputClass}` }), _jsxs("select", { value: (selectedElement.styles?.borderRadius || 'px').replace(/[0-9]/g, '') || 'px', onChange: (e) => {
                                                        const num = parseInt(selectedElement.styles?.borderRadius || '0') || 0;
                                                        updateElement(selectedElement.id, {
                                                            styles: { ...selectedElement.styles, borderRadius: num + e.target.value }
                                                        });
                                                    }, className: `w-20 px-2 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "px", children: "px" }), _jsx("option", { value: "%", children: "%" }), _jsx("option", { value: "em", children: "em" })] })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Box Shadow" }), _jsx("input", { type: "text", value: selectedElement.styles?.boxShadow || '', onChange: (e) => updateElement(selectedElement.id, {
                                                styles: { ...selectedElement.styles, boxShadow: e.target.value }
                                            }), placeholder: "0 4px 6px rgba(0,0,0,0.1)", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { className: "p-4", children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Spacing" }), _jsxs("div", { className: `flex gap-1 mb-4 p-1 rounded ${canvasMode === 'dark' ? 'bg-neutral-700' : 'bg-neutral-200'}`, children: [_jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'desktop' })), className: `flex-1 px-2 py-1.5 text-xs font-medium rounded transition-colors ${state.viewportMode === 'desktop'
                                                        ? 'bg-blue-500 text-white'
                                                        : canvasMode === 'dark'
                                                            ? 'text-neutral-300 hover:bg-neutral-600'
                                                            : 'text-neutral-700 hover:bg-neutral-100'}`, children: _jsx(Monitor, { className: "w-3 h-3 mx-auto" }) }), _jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'tablet' })), className: `flex-1 px-2 py-1.5 text-xs font-medium rounded transition-colors ${state.viewportMode === 'tablet'
                                                        ? 'bg-blue-500 text-white'
                                                        : canvasMode === 'dark'
                                                            ? 'text-neutral-300 hover:bg-neutral-600'
                                                            : 'text-neutral-700 hover:bg-neutral-100'}`, children: _jsx(Tablet, { className: "w-3 h-3 mx-auto" }) }), _jsx("button", { onClick: () => setState(prev => ({ ...prev, viewportMode: 'mobile' })), className: `flex-1 px-2 py-1.5 text-xs font-medium rounded transition-colors ${state.viewportMode === 'mobile'
                                                        ? 'bg-blue-500 text-white'
                                                        : canvasMode === 'dark'
                                                            ? 'text-neutral-300 hover:bg-neutral-600'
                                                            : 'text-neutral-700 hover:bg-neutral-100'}`, children: _jsx(Smartphone, { className: "w-3 h-3 mx-auto" }) })] }), _jsxs("div", { className: "grid grid-cols-2 gap-3", children: [_jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Padding" }), _jsx("input", { type: "text", value: state.viewportMode === 'desktop'
                                                                ? selectedElement.styles?.padding || ''
                                                                : state.viewportMode === 'tablet'
                                                                    ? selectedElement.responsive?.tablet?.padding || ''
                                                                    : selectedElement.responsive?.mobile?.padding || '', onChange: (e) => {
                                                                if (state.viewportMode === 'desktop') {
                                                                    updateElement(selectedElement.id, {
                                                                        styles: { ...selectedElement.styles, padding: e.target.value }
                                                                    });
                                                                }
                                                                else {
                                                                    updateElement(selectedElement.id, {
                                                                        responsive: {
                                                                            ...selectedElement.responsive,
                                                                            [state.viewportMode]: {
                                                                                ...selectedElement.responsive?.[state.viewportMode],
                                                                                padding: e.target.value
                                                                            }
                                                                        }
                                                                    });
                                                                }
                                                            }, placeholder: "10px", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Margin" }), _jsx("input", { type: "text", value: state.viewportMode === 'desktop'
                                                                ? selectedElement.styles?.margin || ''
                                                                : state.viewportMode === 'tablet'
                                                                    ? selectedElement.responsive?.tablet?.margin || ''
                                                                    : selectedElement.responsive?.mobile?.margin || '', onChange: (e) => {
                                                                if (state.viewportMode === 'desktop') {
                                                                    updateElement(selectedElement.id, {
                                                                        styles: { ...selectedElement.styles, margin: e.target.value }
                                                                    });
                                                                }
                                                                else {
                                                                    updateElement(selectedElement.id, {
                                                                        responsive: {
                                                                            ...selectedElement.responsive,
                                                                            [state.viewportMode]: {
                                                                                ...selectedElement.responsive?.[state.viewportMode],
                                                                                margin: e.target.value
                                                                            }
                                                                        }
                                                                    });
                                                                }
                                                            }, placeholder: "10px", className: `w-full px-3 py-2 border rounded ${inputClass}` })] })] }), _jsxs("div", { className: "mt-4", children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Width" }), _jsx("input", { type: "text", value: state.viewportMode === 'desktop'
                                                        ? selectedElement.styles?.width || ''
                                                        : state.viewportMode === 'tablet'
                                                            ? selectedElement.responsive?.tablet?.width || ''
                                                            : selectedElement.responsive?.mobile?.width || '', onChange: (e) => {
                                                        if (state.viewportMode === 'desktop') {
                                                            updateElement(selectedElement.id, {
                                                                styles: { ...selectedElement.styles, width: e.target.value }
                                                            });
                                                        }
                                                        else {
                                                            updateElement(selectedElement.id, {
                                                                responsive: {
                                                                    ...selectedElement.responsive,
                                                                    [state.viewportMode]: {
                                                                        ...selectedElement.responsive?.[state.viewportMode],
                                                                        width: e.target.value
                                                                    }
                                                                }
                                                            });
                                                        }
                                                    }, placeholder: "100%", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { className: "mt-4", children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Height" }), _jsx("input", { type: "text", value: state.viewportMode === 'desktop'
                                                        ? selectedElement.styles?.height || ''
                                                        : state.viewportMode === 'tablet'
                                                            ? selectedElement.responsive?.tablet?.height || ''
                                                            : selectedElement.responsive?.mobile?.height || '', onChange: (e) => {
                                                        if (state.viewportMode === 'desktop') {
                                                            updateElement(selectedElement.id, {
                                                                styles: { ...selectedElement.styles, height: e.target.value }
                                                            });
                                                        }
                                                        else {
                                                            updateElement(selectedElement.id, {
                                                                responsive: {
                                                                    ...selectedElement.responsive,
                                                                    [state.viewportMode]: {
                                                                        ...selectedElement.responsive?.[state.viewportMode],
                                                                        height: e.target.value
                                                                    }
                                                                }
                                                            });
                                                        }
                                                    }, placeholder: "auto", className: `w-full px-3 py-2 border rounded ${inputClass}` })] })] })] })), rightPanelTab === 'advanced' && (_jsxs("div", { children: [_jsxs("div", { className: `p-4 border-b ${borderClass}`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Advanced" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "CSS ID" }), _jsx("input", { type: "text", value: selectedElement.props.cssId || '', onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, cssId: e.target.value }
                                            }), placeholder: "my-element-id", className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "CSS Classes" }), _jsx("input", { type: "text", value: selectedElement.props.cssClasses || '', onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, cssClasses: e.target.value }
                                            }), placeholder: "class-1 class-2", className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Custom CSS" }), _jsx("textarea", { value: selectedElement.props.customCSS || '', onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, customCSS: e.target.value }
                                            }), rows: 6, placeholder: "/* Custom CSS */\nselector {\n  property: value;\n}", className: `w-full px-3 py-2 border rounded font-mono text-sm ${inputClass}` })] }), _jsxs("div", { className: `p-4 border-b ${borderClass}`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Motion Effects" }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Entrance Animation" }), _jsxs("select", { value: selectedElement.props.animation || 'none', onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, animation: e.target.value }
                                            }), className: `w-full px-3 py-2 border rounded mb-3 ${selectClass}`, children: [_jsx("option", { value: "none", children: "None" }), _jsx("option", { value: "fade-in", children: "Fade In" }), _jsx("option", { value: "fade-in-up", children: "Fade In Up" }), _jsx("option", { value: "fade-in-down", children: "Fade In Down" }), _jsx("option", { value: "fade-in-left", children: "Fade In Left" }), _jsx("option", { value: "fade-in-right", children: "Fade In Right" }), _jsx("option", { value: "zoom-in", children: "Zoom In" }), _jsx("option", { value: "slide-in-up", children: "Slide In Up" }), _jsx("option", { value: "slide-in-down", children: "Slide In Down" })] }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Animation Duration (ms)" }), _jsx("input", { type: "number", value: selectedElement.props.animationDuration || 600, onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, animationDuration: parseInt(e.target.value) }
                                            }), min: "100", max: "3000", step: "100", className: `w-full px-3 py-2 border rounded mb-3 ${inputClass}` }), _jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Animation Delay (ms)" }), _jsx("input", { type: "number", value: selectedElement.props.animationDelay || 0, onChange: (e) => updateElement(selectedElement.id, {
                                                props: { ...selectedElement.props, animationDelay: parseInt(e.target.value) }
                                            }), min: "0", max: "5000", step: "100", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { className: `p-4`, children: [_jsx("h4", { className: `font-medium mb-3 ${headingClass}`, children: "Visibility" }), _jsxs("label", { className: `flex items-center gap-2 mb-2 ${labelClass} cursor-pointer`, children: [_jsx("input", { type: "checkbox", checked: selectedElement.props.hideOnDesktop || false, onChange: (e) => updateElement(selectedElement.id, {
                                                        props: { ...selectedElement.props, hideOnDesktop: e.target.checked }
                                                    }), className: "w-4 h-4" }), _jsx("span", { children: "Hide on Desktop" })] }), _jsxs("label", { className: `flex items-center gap-2 mb-2 ${labelClass} cursor-pointer`, children: [_jsx("input", { type: "checkbox", checked: selectedElement.props.hideOnTablet || false, onChange: (e) => updateElement(selectedElement.id, {
                                                        props: { ...selectedElement.props, hideOnTablet: e.target.checked }
                                                    }), className: "w-4 h-4" }), _jsx("span", { children: "Hide on Tablet" })] }), _jsxs("label", { className: `flex items-center gap-2 ${labelClass} cursor-pointer`, children: [_jsx("input", { type: "checkbox", checked: selectedElement.props.hideOnMobile || false, onChange: (e) => updateElement(selectedElement.id, {
                                                        props: { ...selectedElement.props, hideOnMobile: e.target.checked }
                                                    }), className: "w-4 h-4" }), _jsx("span", { children: "Hide on Mobile" })] })] })] }))] }));
            })(), showDeviceManager && (_jsx("div", { className: "fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50", onClick: () => setShowDeviceManager(false), children: _jsxs("div", { className: `w-full max-w-6xl max-h-[90vh] overflow-y-auto rounded-lg shadow-2xl ${canvasMode === 'dark' ? 'bg-neutral-800' : 'bg-white'}`, onClick: (e) => e.stopPropagation(), children: [_jsx("div", { className: `p-6 border-b ${canvasMode === 'dark' ? 'border-neutral-700' : 'border-gray-200'}`, children: _jsxs("div", { className: "flex items-center justify-between", children: [_jsxs("h2", { className: `text-2xl font-bold flex items-center gap-3 ${headingClass}`, children: [_jsx(Smartphone, { className: "w-7 h-7" }), "Device Resolutions Manager"] }), _jsx("button", { onClick: () => setShowDeviceManager(false), className: `p-2 rounded-lg ${canvasMode === 'dark'
                                            ? 'hover:bg-neutral-700 text-neutral-300'
                                            : 'hover:bg-gray-100 text-gray-600'}`, children: "\u2715" })] }) }), _jsxs("div", { className: "grid grid-cols-1 lg:grid-cols-2 gap-6 p-6", children: [_jsxs("div", { children: [_jsx("h3", { className: `text-lg font-semibold mb-4 ${headingClass}`, children: editingDeviceId ? 'Edit Device' : 'Add New Device' }), _jsxs("div", { className: "space-y-4", children: [_jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Device Key *" }), _jsx("input", { type: "text", value: deviceFormData.device_key, onChange: (e) => setDeviceFormData({ ...deviceFormData, device_key: e.target.value }), placeholder: "iphone-18", disabled: !!editingDeviceId, className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Device Name *" }), _jsx("input", { type: "text", value: deviceFormData.device_name, onChange: (e) => setDeviceFormData({ ...deviceFormData, device_name: e.target.value }), placeholder: "iPhone 18", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Device Type *" }), _jsxs("select", { value: deviceFormData.device_type, onChange: (e) => setDeviceFormData({ ...deviceFormData, device_type: e.target.value }), className: `w-full px-3 py-2 border rounded ${selectClass}`, children: [_jsx("option", { value: "mobile", children: "Mobile" }), _jsx("option", { value: "tablet", children: "Tablet" }), _jsx("option", { value: "desktop", children: "Desktop" })] })] }), _jsxs("div", { className: "grid grid-cols-2 gap-3", children: [_jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Width (px) *" }), _jsx("input", { type: "number", value: deviceFormData.width_px, onChange: (e) => setDeviceFormData({ ...deviceFormData, width_px: parseInt(e.target.value) }), className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Height (px)" }), _jsx("input", { type: "number", value: deviceFormData.height_px || '', onChange: (e) => setDeviceFormData({ ...deviceFormData, height_px: parseInt(e.target.value) }), className: `w-full px-3 py-2 border rounded ${inputClass}` })] })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Label (shown in dropdown) *" }), _jsx("input", { type: "text", value: deviceFormData.label, onChange: (e) => setDeviceFormData({ ...deviceFormData, label: e.target.value }), placeholder: "iPhone 18 (410px)", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { className: "grid grid-cols-2 gap-3", children: [_jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Manufacturer" }), _jsx("input", { type: "text", value: deviceFormData.manufacturer, onChange: (e) => setDeviceFormData({ ...deviceFormData, manufacturer: e.target.value }), placeholder: "Apple", className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Model" }), _jsx("input", { type: "text", value: deviceFormData.model, onChange: (e) => setDeviceFormData({ ...deviceFormData, model: e.target.value }), placeholder: "iPhone 18", className: `w-full px-3 py-2 border rounded ${inputClass}` })] })] }), _jsxs("div", { className: "grid grid-cols-2 gap-3", children: [_jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Release Year" }), _jsx("input", { type: "number", value: deviceFormData.release_year, onChange: (e) => setDeviceFormData({ ...deviceFormData, release_year: parseInt(e.target.value) }), className: `w-full px-3 py-2 border rounded ${inputClass}` })] }), _jsxs("div", { children: [_jsx("label", { className: `block text-sm font-medium mb-1 ${labelClass}`, children: "Display Order" }), _jsx("input", { type: "number", value: deviceFormData.display_order, onChange: (e) => setDeviceFormData({ ...deviceFormData, display_order: parseInt(e.target.value) }), className: `w-full px-3 py-2 border rounded ${inputClass}` })] })] }), _jsx("div", { children: _jsxs("label", { className: `flex items-center gap-2 ${labelClass} cursor-pointer`, children: [_jsx("input", { type: "checkbox", checked: deviceFormData.is_default, onChange: (e) => setDeviceFormData({ ...deviceFormData, is_default: e.target.checked }), className: "w-4 h-4" }), _jsx("span", { children: "Set as default device for this type" })] }) }), _jsxs("div", { className: "flex gap-3 pt-4", children: [_jsx("button", { onClick: saveDevice, className: "flex-1 px-4 py-2 text-white bg-green-600 hover:bg-green-700 rounded font-medium", children: editingDeviceId ? 'Update Device' : 'Add Device' }), editingDeviceId && (_jsx("button", { onClick: resetDeviceForm, className: `px-4 py-2 rounded font-medium ${canvasMode === 'dark'
                                                                ? 'bg-neutral-700 hover:bg-neutral-600 text-neutral-200'
                                                                : 'bg-gray-200 hover:bg-gray-300 text-gray-700'}`, children: "Cancel" }))] })] })] }), _jsxs("div", { children: [_jsxs("h3", { className: `text-lg font-semibold mb-4 ${headingClass}`, children: ["Existing Devices (", allDevices.length, ")"] }), _jsxs("div", { className: "space-y-2 max-h-[600px] overflow-y-auto", children: [allDevices.length === 0 && (_jsx("div", { className: `text-center py-8 ${labelClass}`, children: "No devices found. Add your first device!" })), allDevices.map((device) => (_jsx("div", { className: `p-4 rounded-lg border ${canvasMode === 'dark'
                                                        ? 'bg-neutral-700 border-neutral-600'
                                                        : 'bg-gray-50 border-gray-200'} ${!device.is_active ? 'opacity-50' : ''}`, children: _jsxs("div", { className: "flex items-start justify-between", children: [_jsxs("div", { className: "flex-1", children: [_jsxs("div", { className: "flex items-center gap-2", children: [_jsx("h4", { className: `font-semibold ${headingClass}`, children: device.device_name }), device.is_default && (_jsx("span", { className: "px-2 py-0.5 text-xs bg-blue-500 text-white rounded", children: "DEFAULT" })), !device.is_active && (_jsx("span", { className: "px-2 py-0.5 text-xs bg-red-500 text-white rounded", children: "INACTIVE" }))] }), _jsxs("p", { className: `text-sm mt-1 ${labelClass}`, children: [device.label, " \u2022 ", device.device_type] }), device.manufacturer && (_jsxs("p", { className: `text-xs mt-1 ${labelClass}`, children: [device.manufacturer, " ", device.model, " ", device.release_year && `(${device.release_year})`] }))] }), _jsxs("div", { className: "flex gap-2", children: [_jsx("button", { onClick: () => editDevice(device), className: `px-3 py-1 text-sm rounded ${canvasMode === 'dark'
                                                                            ? 'bg-blue-600 hover:bg-blue-700 text-white'
                                                                            : 'bg-blue-500 hover:bg-blue-600 text-white'}`, children: "Edit" }), _jsx("button", { onClick: () => deleteDevice(device.id), className: `px-3 py-1 text-sm rounded ${canvasMode === 'dark'
                                                                            ? 'bg-red-600 hover:bg-red-700 text-white'
                                                                            : 'bg-red-500 hover:bg-red-600 text-white'}`, children: "Delete" })] })] }) }, device.id)))] })] })] })] }) }))] }));
}
export default VisualPageBuilder;
// Backward compatibility alias
export { VisualPageBuilder as ElementorBuilder };
//# sourceMappingURL=ElementorBuilder.js.map