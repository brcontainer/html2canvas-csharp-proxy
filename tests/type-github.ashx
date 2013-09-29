<%@ WebHandler Language="C#" Debug="true" Class="FireTest" %>

using System;
using System.IO;
using System.Web;
using System.Net;
using System.Text;

public class FireTest : IHttpHandler {
	public void ProcessRequest (HttpContext context) {
    //test type in github
    if(i>127){
      
    }
    if(i<127){
      
    }
	}

	public bool IsReusable {
		get {
			return false;
		}
	}
}
