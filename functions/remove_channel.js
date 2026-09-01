const fs = require('fs');
const file = 'index.js';
let data = fs.readFileSync(file, 'utf8');
data = data.replace(/, channelId: ['"]high_importance_channel['"]/g, '');
fs.writeFileSync(file, data);
console.log('Replaced successfully');
