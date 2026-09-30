###################################################
# Stage: base
#
# This base stage ensures all other stages use the
# same smaller Debian-based Node.js image.
###################################################
FROM node:22-slim AS base

WORKDIR /usr/local/app


################## CLIENT STAGES ##################


###################################################
# Stage: client-base
#
# Installs the client dependencies and copies the
# client source files.
###################################################
FROM base AS client-base

COPY client/package.json client/package-lock.json ./
COPY .npmrc ./

RUN npm ci

COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src


###################################################
# Stage: client-dev
#
# Starts the Vite development server.
###################################################
FROM client-base AS client-dev

CMD ["npm", "run", "dev"]


###################################################
# Stage: client-build
#
# Builds the static client application.
###################################################
FROM client-base AS client-build

RUN npm run build


################# BACKEND STAGES ##################


###################################################
# Stage: sqlite3-build
#
# Installs the build tools needed to compile the
# sqlite3 native Node.js module. These tools remain
# in this temporary stage and are not included in
# the final production image.
###################################################
FROM base AS sqlite3-build

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        make \
        g++ && \
    rm -rf /var/lib/apt/lists/*

COPY backend/package.json backend/package-lock.json ./
COPY .npmrc ./

RUN npm ci && \
    cd node_modules/sqlite3 && \
    ../.bin/node-gyp rebuild


###################################################
# Stage: backend-dev
#
# Installs the backend dependencies and copies the
# compiled sqlite3 binary from the build stage.
###################################################
FROM base AS backend-dev

COPY backend/package.json backend/package-lock.json ./
COPY .npmrc ./

RUN npm ci

COPY --from=sqlite3-build \
    /usr/local/app/node_modules/sqlite3/build \
    ./node_modules/sqlite3/build

COPY backend/spec ./spec
COPY backend/src ./src

CMD ["npm", "run", "dev"]


###################################################
# Stage: test
#
# Runs the backend automated tests.
###################################################
FROM backend-dev AS test

RUN npm run test


###################################################
# Stage: final
#
# Creates the smaller production image containing
# only the production dependencies, backend source,
# compiled sqlite3 module, and built client.
###################################################
FROM base AS final

ENV NODE_ENV=production

COPY --from=test \
    /usr/local/app/package.json \
    /usr/local/app/package-lock.json \
    ./

COPY .npmrc ./

RUN npm ci --omit=dev && \
    npm cache clean --force

COPY --from=sqlite3-build \
    /usr/local/app/node_modules/sqlite3/build \
    ./node_modules/sqlite3/build

COPY backend/src ./src

COPY --from=client-build \
    /usr/local/app/dist \
    ./src/static

RUN chown -R node:node /usr/local/app

USER node

EXPOSE 3000

CMD ["node", "src/index.js"]
