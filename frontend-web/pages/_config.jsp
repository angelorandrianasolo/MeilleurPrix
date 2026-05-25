<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%
  String apiUrl = application.getInitParameter("apiBaseUrl");
  if (apiUrl == null || apiUrl.trim().isEmpty()) {
    apiUrl = "http://localhost:3000";
  }
  apiUrl = apiUrl.replaceAll("\"", "");
%>
<script>window.API_URL = "<%= apiUrl %>";</script>
