import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				main: resolve(__dirname, 'index.html'),
			},
			output: {
				assetFileNames: 'assets/[name].[ext]',
				chunkFileNames: 'assets/[name].js',
				entryFileNames: 'assets/[name]-[hash].js',
			}
		}
	},
	server: {
		port: 3000,
	}
});
