import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
	build: {
		emptyOutDir: false, // Don't clear dist, as main build might have run
		rollupOptions: {
			input: {
				'content-script': resolve(__dirname, 'src/extension.ts'),
			},
			output: {
				entryFileNames: 'content-script.js',
				// Force single bundle
				inlineDynamicImports: true,
				format: 'iife', // Immediately Invoked Function Expression is best for content scripts to avoid variable leaks
			}
		}
	},
	// Ensure we define how to handle .ts files if needed, but Vite defaults usually work.
});
