// Isolated fixture preview for visual QA; never connects to live Firebase.
import {createServer, loadConfigFromFile} from 'vite';
const loaded=await loadConfigFromFile({command:'serve',mode:'development'});
const fixtureOnly={name:'fixture-formatting-preview',configureServer(server){server.middlewares.use((req,res,next)=>{if(req.url?.split('?')[0]==='/firebase-connection.local.json'){res.statusCode=404;res.end();return}next()})}};
const server=await createServer({...loaded.config,configFile:false,plugins:[fixtureOnly,...loaded.config.plugins],server:{...loaded.config.server,host:'127.0.0.1',port:5174,strictPort:true}});
await server.listen();console.log('Fixture-only UI preview: http://127.0.0.1:5174');
