import { createApp } from 'vue';
import App from './App.vue';

document.body.style.margin = '0';

createApp(App).mount('#app');

const appShell = document.querySelector('#app [data-theme]');
const themeColor = appShell && getComputedStyle(appShell).getPropertyValue('--canvas').trim();
const themeColorMeta = document.querySelector('meta[name="theme-color"]');
if (themeColor && themeColorMeta) themeColorMeta.content = themeColor;
