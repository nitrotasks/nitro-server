module.exports = {
  "env": {
    "node": true,
    "browser": false,
    "es6": true,
    "mocha": true
  },
  "extends": "eslint:recommended",
  "parser": "babel-eslint",
  "parserOptions": {
    "ecmaFeatures": {},
    "sourceType": "module"
  },
  "plugins": [],
  "settings": {},
  "rules": {
    "indent": [
      "error",
      2
    ],
    "linebreak-style": [
      "error",
      "unix"
    ],
    "quotes": [
      "error",
      "single"
    ],
    "semi": [
      "error",
      "never"
    ]
  }
}