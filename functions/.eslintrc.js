module.exports = {
  
    "env": {
      "node": true,
      "es2021": true,
    },
    "extends": [
      "google",
    ],
    "rules": {
      "object-curly-spacing": ["error", "never"],
      "comma-dangle": ["error", "always-multiline"],
      "eol-last": ["error", "always"],
      "arrow-parens": ["error", "always"],
      "node/no-missing-require": "off",
    },
  
};
