import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
	build: {
		emptyOutDir: false,
		rollupOptions: {
			input: {
				'background': resolve(__dirname, 'src/background.ts'),
			},
			output: {
				entryFileNames: 'background.js',
				inlineDynamicImports: true, // Self-contained bundle
				format: 'es', // Service workers support ES modules
			}
		}
	},
});
