<%--
/**
 * Copyright (c) 2000-2012 Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */
--%>

<%@ include file="/html/portlet/init.jsp" %>

<%@ page import="com.liferay.portal.kernel.portletdisplaytemplate.PortletDisplayTemplateHandler" %><%@
page import="com.liferay.portal.kernel.portletdisplaytemplate.PortletDisplayTemplateHandlerRegistryUtil" %><%@
page import="com.liferay.portal.kernel.repository.model.FileEntry" %><%@
page import="com.liferay.portal.kernel.sanitizer.SanitizerException" %><%@
page import="com.liferay.portal.kernel.sanitizer.SanitizerUtil" %><%@
page import="com.liferay.portal.kernel.search.Hits" %><%@
page import="com.liferay.portal.kernel.search.Indexer" %><%@
page import="com.liferay.portal.kernel.search.IndexerRegistryUtil" %><%@
page import="com.liferay.portal.kernel.search.SearchContext" %><%@
page import="com.liferay.portal.kernel.search.SearchContextFactory" %><%@
page import="com.liferay.portlet.asset.model.AssetEntry" %><%@
page import="com.liferay.portlet.asset.service.AssetEntryLocalServiceUtil" %><%@
page import="com.liferay.portlet.asset.service.AssetEntryServiceUtil" %><%@
page import="com.liferay.portlet.asset.service.AssetTagLocalServiceUtil" %><%@
page import="com.liferay.portlet.asset.service.persistence.AssetEntryQuery" %><%@
page import="com.liferay.portlet.asset.util.AssetUtil" %><%@
page import="com.liferay.portlet.documentlibrary.DuplicateFileException" %><%@
page import="com.liferay.portlet.documentlibrary.FileNameException" %><%@
page import="com.liferay.portlet.documentlibrary.FileSizeException" %><%@
page import="com.liferay.portlet.documentlibrary.model.DLFileEntry" %><%@
page import="com.liferay.portlet.documentlibrary.util.DLUtil" %><%@
page import="com.liferay.portlet.documentlibrary.util.DocumentConversionUtil" %><%@
page import="com.liferay.portlet.portletdisplaytemplate.util.PortletDisplayTemplateUtil" %><%@
page import="com.liferay.portlet.trash.model.TrashEntry" %><%@
page import="com.liferay.portlet.trash.service.TrashEntryLocalServiceUtil" %><%@
page import="com.liferay.portlet.trash.util.TrashUtil" %><%@
page import="com.liferay.portlet.wiki.DuplicateNodeNameException" %><%@
page import="com.liferay.portlet.wiki.DuplicatePageException" %><%@
page import="com.liferay.portlet.wiki.ImportFilesException" %><%@
page import="com.liferay.portlet.wiki.NoSuchNodeException" %><%@
page import="com.liferay.portlet.wiki.NoSuchPageException" %><%@
page import="com.liferay.portlet.wiki.NodeNameException" %><%@
page import="com.liferay.portlet.wiki.PageContentException" %><%@
page import="com.liferay.portlet.wiki.PageTitleException" %><%@
page import="com.liferay.portlet.wiki.PageVersionException" %><%@
page import="com.liferay.portlet.wiki.WikiFormatException" %><%@
page import="com.liferay.portlet.wiki.importers.WikiImporterKeys" %><%@
page import="com.liferay.portlet.wiki.model.WikiNode" %><%@
page import="com.liferay.portlet.wiki.model.WikiPage" %><%@
page import="com.liferay.portlet.wiki.model.WikiPageConstants" %><%@
page import="com.liferay.portlet.wiki.model.WikiPageDisplay" %><%@
page import="com.liferay.portlet.wiki.model.WikiPageResource" %><%@
page import="com.liferay.portlet.wiki.model.impl.WikiPageImpl" %><%@
page import="com.liferay.portlet.wiki.service.WikiNodeLocalServiceUtil" %><%@
page import="com.liferay.portlet.wiki.service.WikiPageLocalServiceUtil" %><%@
page import="com.liferay.portlet.wiki.service.WikiPageResourceLocalServiceUtil" %><%@
page import="com.liferay.portlet.wiki.service.WikiPageServiceUtil" %><%@
page import="com.liferay.portlet.wiki.service.permission.WikiNodePermission" %><%@
page import="com.liferay.portlet.wiki.service.permission.WikiPagePermission" %><%@
page import="com.liferay.portlet.wiki.service.permission.WikiPermission" %><%@
page import="com.liferay.portlet.wiki.util.WikiCacheUtil" %><%@
page import="com.liferay.portlet.wiki.util.WikiPageAttachmentsUtil" %><%@
page import="com.liferay.portlet.wiki.util.WikiUtil" %><%@
page import="com.liferay.portlet.wiki.util.comparator.PageVersionComparator" %><%@
page import="com.liferay.util.RSSUtil" %>

<%
PortletPreferences preferences = renderRequest.getPreferences();

String portletResource = ParamUtil.getString(request, "portletResource");

if (Validator.isNotNull(portletResource)) {
	preferences = PortletPreferencesFactoryUtil.getPortletSetup(request, portletResource);
}

String displayStyle = preferences.getValue("displayStyle", StringPool.BLANK);
boolean enableRelatedAssets = GetterUtil.getBoolean(preferences.getValue("enableRelatedAssets", null), true);
boolean enablePageRatings = PropsValues.WIKI_PAGE_RATINGS_ENABLED && GetterUtil.getBoolean(preferences.getValue("enablePageRatings", null), true);
boolean enableComments = PropsValues.WIKI_PAGE_COMMENTS_ENABLED && GetterUtil.getBoolean(preferences.getValue("enableComments", null), true);
boolean enableCommentRatings = GetterUtil.getBoolean(preferences.getValue("enableCommentRatings", null), true);

List<WikiNode> allNodes = WikiNodeLocalServiceUtil.getNodes(scopeGroupId);
List<String> allNodeNames = WikiUtil.getNodeNames(allNodes);

String[] visibleNodes = null;

String visibleNodesPreference = preferences.getValue("visibleNodes", null);

if (visibleNodesPreference != null) {
	visibleNodes = StringUtil.split(visibleNodesPreference);

	allNodes = WikiUtil.orderNodes(allNodes, visibleNodes);
}
else {
	visibleNodes = allNodeNames.toArray(new String[allNodeNames.size()]);
}

String[] hiddenNodes = StringUtil.split(preferences.getValue("hiddenNodes", null));

boolean enableRSS = !PortalUtil.isRSSFeedsEnabled() ? false : GetterUtil.getBoolean(preferences.getValue("enableRss", null), true);
int rssDelta = GetterUtil.getInteger(preferences.getValue("rssDelta", StringPool.BLANK), SearchContainer.DEFAULT_DELTA);
String rssDisplayStyle = preferences.getValue("rssDisplayStyle", RSSUtil.DISPLAY_STYLE_DEFAULT);
String rssFeedType = preferences.getValue("rssFeedType", RSSUtil.FEED_TYPE_DEFAULT);

Format dateFormatDateTime = FastDateFormatFactoryUtil.getDateTime(locale, timeZone);
%>

<%@ include file="/html/portlet/wiki/init-ext.jsp" %>