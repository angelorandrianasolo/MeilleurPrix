# Déploiement sur Apache Tomcat 9

Ce frontend utilise **JSP 2.3** et **Servlet 4.0** (Java EE 8), compatible **Tomcat 9.0.x**.

> Tomcat 10+ utilise Jakarta EE (`jakarta.*`) : le `web.xml` de ce projet n'est **pas** compatible Tomcat 10 sans migration.

## Étapes

1. **Compiler / copier** le dossier `frontend-web` dans :

   ```
   TOMCAT_HOME/webapps/meilleur-prix/
   ```

2. **Démarrer Tomcat 9** :

   ```bat
   %TOMCAT_HOME%\bin\startup.bat
   ```

3. **Ouvrir** :

   ```
   http://localhost:8080/meilleur-prix/pages/login.jsp
   ```

4. **Configurer l'API Node.js** — modifier dans `WEB-INF/web.xml` :

   ```xml
   <context-param>
     <param-name>apiBaseUrl</param-name>
     <param-value>http://localhost:3000</param-value>
   </context-param>
   ```

   Ou créer `TOMCAT_HOME/conf/Catalina/localhost/meilleur-prix.xml` :

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <Context>
     <Parameter name="apiBaseUrl" value="http://localhost:3000" override="true"/>
   </Context>
   ```

5. Le **backend Node.js** doit tourner sur le port configuré (`npm start` dans `backend/`).

## Prérequis Tomcat 9

- **JDK 8** ou **JDK 11** (recommandé pour Tomcat 9)
- Variable `JAVA_HOME` pointant vers le JDK
- `CATALINA_HOME` = répertoire Tomcat 9

## Structure déployée

```
meilleur-prix/
├── index.jsp
├── css/
├── js/
├── pages/
└── WEB-INF/
    └── web.xml
```
