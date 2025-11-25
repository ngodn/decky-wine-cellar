import deckyPlugin from "@decky/rollup";
import externalGlobals from 'rollup-plugin-external-globals';

export default deckyPlugin({
  // Add your extra Rollup options here
  plugins: [
    // Add the missing react/jsx-runtime mapping that @decky/rollup doesn't include
    // Also add process, path, and url hacks for react-markdown compatibility
    externalGlobals({
      'react/jsx-runtime': 'SP_JSX',
      'process': '{cwd: () => {}}',
      'path': '{dirname: () => {}, join: () => {}, basename: () => {}, extname: () => {}}',
      'url': '{fileURLToPath: (f) => f}',
    }),
  ],
});
