/**
 * Test script to verify widget registration
 */

import { widgetRegistry } from './dist/registry/index.js';

// Import widgets to trigger registration
import './dist/widgets/MetricsCardsWidget/register.js';
import './dist/widgets/ServiceStatusWidget/register.js';
import './dist/widgets/RecentActivityWidget/register.js';

console.log('\n=== Widget Registry Test ===\n');

const allWidgets = widgetRegistry.getAll();
console.log(`Total widgets registered: ${allWidgets.length}`);

if (allWidgets.length === 0) {
  console.log('\n⚠️  No widgets found in registry!');
  process.exit(1);
}

console.log('\nRegistered widgets:');
allWidgets.forEach((widget, index) => {
  console.log(`  ${index + 1}. ${widget.metadata.id} - ${widget.metadata.name}`);
  console.log(`     Category: ${widget.metadata.category}`);
  console.log(`     Description: ${widget.metadata.description}`);
  console.log('');
});

// Check for the 3 expected widgets
const expectedWidgets = [
  'metrics-cards',
  'service-status',
  'recent-activity'
];

console.log('Verification:');
let allFound = true;
expectedWidgets.forEach(id => {
  const widget = widgetRegistry.get(id);
  if (widget) {
    console.log(`  ✅ ${id} - Found`);
  } else {
    console.log(`  ❌ ${id} - NOT FOUND`);
    allFound = false;
  }
});

if (allFound) {
  console.log('\n✅ All 3 pilot widgets successfully registered!\n');
  process.exit(0);
} else {
  console.log('\n❌ Some widgets are missing from registry\n');
  process.exit(1);
}
