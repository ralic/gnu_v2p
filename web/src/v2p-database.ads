------------------------------------------------------------------------------
--                              Vision2Pixels                               --
--                                                                          --
--                         Copyright (C) 2006-2010                          --
--                      Pascal Obry - Olivier Ramonat                       --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.       --
------------------------------------------------------------------------------

with Ada.Strings.Unbounded;

with AWS.Templates;

with V2P.Navigation_Links;

private with Ada.Task_Attributes;
private with DB;

package V2P.Database is

   use AWS;
   use Ada.Strings.Unbounded;

   No_Database    : exception;

   Database_Error :  exception;

   Parameter_Error : exception;
   --  Raise if the given parameter value does not exist in database

   type Filter_Mode is
     (Today, Two_Days, Seven_Days, Fifteen_Days, One_Month, All_Messages);
   --  Kind of filter to apply when returning the list of posts, see
   --  Get_Threads.

   subtype Id is Natural;
   Empty_Id : constant Id;

   function To_String (Id : in Database.Id) return String;
   pragma Inline (To_String);
   --  Returns Id image

   type Forum_Filter is (Forum_Text, Forum_Photo, Forum_All);

   type Forum_Type is new Forum_Filter range Forum_Text .. Forum_Photo;

   type Order_Direction is (DESC, ASC);

   type Forum_Sort is
     (Last_Posted, Last_Commented, Best_Noted, Need_Attention);

   type Image_Size is (Thumb_Size, Medium_Size, Max_Size);

   type User_Settings is record
      Page_Size              : Navigation_Links.Page_Size;
      Filter                 : Filter_Mode;
      Sort                   : Forum_Sort;
      Image_Size             : Database.Image_Size;
      CSS_URL                : Unbounded_String;
      Accept_Private_Message : Boolean;
   end record;

   type User_Data is record
      UID         : Unbounded_String;
      Password    : Unbounded_String;
      Email       : Unbounded_String;
      Admin       : Boolean;
      Preferences : User_Settings;
   end record;

   type Select_Mode is (Everything, Navigation_Only);

   type User_Sort is
     (Date_Created, Last_Connected, Nb_Comments, Nb_Photos, Nb_CdC);

   No_User_Data          : constant User_Data;
   Default_User_Settings : constant User_Settings;

   function Get_Forums
     (Filter : in Forum_Filter;
      TZ     : in String;
      Login  : in String)
      return Templates.Translate_Set;
   --  Returns the forum list
   --  If filter is Forum_Photo or Forum_Text and only one forum found, then
   --  returns the category list in that forum

   function Get_Forum (Fid, Tid : in Id) return Templates.Translate_Set;
   --  Returns the DB line for the given forum. If Fid is empty it uses the Tid
   --  information to get the corresponding forum Id.

   function Get_Forum_Id (Tid : in Id) return Id;
   --  Returns the FID corresponding to the given Tid

   function Get_Forum_Type (Tid : in Id) return V2P.Database.Forum_Type;
   --  Returns the forum type from a Tid

   procedure Get_Threads
     (Fid           : in     Id := Empty_Id;
      Login         : in     String := "";
      User          : in     String := "";
      Admin         : in     Boolean;
      Forum         : in     Forum_Filter := Forum_All;
      Page_Size     : in     Navigation_Links.Page_Size :=
        Navigation_Links.Default_Page_Size;
      Filter        : in     Filter_Mode := All_Messages;
      Filter_Cat    : in     String      := "";
      Order_Dir     : in     Order_Direction := DESC;
      Sorting       : in     Forum_Sort := Last_Posted;
      Only_Revealed : in     Boolean := False;
      From          : in out Positive;
      Mode          : in     Select_Mode := Everything;
      Navigation    :    out Navigation_Links.Post_Ids.Vector;
      Set           :    out Templates.Translate_Set;
      Nb_Lines      :    out Natural;
      Total_Lines   :    out Natural;
      TZ            : in     String);
   --  Returns all threads for a given forum.
   --  Returns navigation links to store in context.
   --  Set Revealed to True to retreive only revealed photos.

   function Get_Latest_Posts
     (Limit         : in Positive;
      TZ            : in String;
      Add_Date      : in Boolean := False;
      Photo_Only    : in Boolean := False;
      From_User     : in String  := "";
      Show_Category : in Boolean := False) return Templates.Translate_Set;
   --  Returns the Limit latest posts from all photo based forums

   function Get_Latest_Comments
     (Limit : in Positive) return Templates.Translate_Set;
   --  Returns the Limit latest posts from all forums

   function Get_Latest_Users
     (Limit : in Positive) return Templates.Translate_Set;
   --  Returns the Limit latest registered users

   function Get_Thumbnail (Post : in Id) return String;
   --  Returns the thumbnail filename of the photo
   --  associated with the given post

   function Get_Categories (Fid : in Id) return Templates.Translate_Set;
   --  Returns all categories for the given forum

   function Get_Category (Tid : in Id) return Templates.Translate_Set;
   --  Returns the category for the given thread

   procedure Set_Category (Tid : in Id; Category_Id : in Id);
   --  Set the category of the given post

   function Get_Category_Full_Name (CID : in String) return String;
   --  Returns a category name "Forum/Category" for the given id

   function Get_Post
     (Tid        : in Id;
      Forum_Type : in V2P.Database.Forum_Type;
      TZ         : in String;
      Admin      : in     Boolean) return Templates.Translate_Set;
   --  Returns the post information (no comments)

   function Get_Comment
     (Cid : in Id; TZ : in String) return Templates.Translate_Set;
   --  Returns a comment for the given comment id

   function Get_Comments
     (Tid : in Id; Login, TZ : in String) return Templates.Translate_Set;
   --  Returns all comments for the given thread

   function Get_User_Data (Uid : in String) return User_Data;
   --  Returns the user's data. Returns the No_User_Data if User cannot be
   --  found into the database.

   function Get_User_To_Validate_Data (Uid : in String) return User_Data;
   --  As above but for user not yet validated

   function Get_User_Stats
     (Uid, TZ : in String) return Templates.Translate_Set;
   --  Returns the stats for the given user or No_User_Stats if user cannot be
   --  found into the database.

   function Get_User_Data_From_Email (Email : in String) return User_Data;
   --  Returns the user's data for the given e-mail. Returns No_User_Data
   --  if the Email cannot be found into the database.

   procedure Set_Last_Logged (Uid : in String);
   --  Set last logged status in the database

   function Get_User_Comment
     (Uid     : in String;
      Limit   : in Positive;
      Textify : in Boolean := False) return Templates.Translate_Set;
   --  Returns user's comments

   function Get_User_Last_Photo
     (Uid : in String) return Templates.Translate_Set;
   --  Returns user's last photo (in the user photo queue)

   function Get_Users
     (From  : in Positive;
      Sort  : in User_Sort;
      Order : in Order_Direction;
      TZ    : in String) return Templates.Translate_Set;
   --  Returns information about N users starting at the given Offset

   function Get_CdC (From : in Positive) return Templates.Translate_Set;
   --  Returns all CdC photos

   function Get_CdC_Info return Templates.Translate_Set;
   --  Returns the current CdC information

   function Get_Metadata (Tid : in Id) return Templates.Translate_Set;
   --  Returns photo geographic metadata from thread if

   function Get_Exif (Tid : in Id) return Templates.Translate_Set;
   --  Returns photo exif metadata, get them from the image if needed and
   --  update the database.

   function Get_Photo_Of_The_Week return Templates.Translate_Set;
   --  Returns photo of the week

   function Toggle_Hidden_Status (Tid : in Id) return Templates.Translate_Set;
   --  Toggle Tid hidden status and returns the new status

   function Insert_Comment
     (Uid       : in String;
      Anonymous : in String;
      Thread    : in Id;
      Name      : in String;
      Comment   : in String;
      Pid       : in Id) return Id;
   --  Insert comment Name/Comment into the given forum and thread,
   --  Returns Comment Id.

   function Insert_Photo
     (Uid           : in String;
      Filename      : in String;
      Height        : in Integer;
      Width         : in Integer;
      Medium_Height : in Integer;
      Medium_Width  : in Integer;
      Thumb_Height  : in Integer;
      Thumb_Width   : in Integer;
      Size          : in Integer) return String;
   --  Insert a new photo into the database, returns photo id

   procedure Insert_Metadata
     (Pid                     : in Id;
      Geo_Latitude            : in Float;
      Geo_Longitude           : in Float;
      Geo_Latitude_Formatted  : in String;
      Geo_Longitude_Formatted : in String);
   --  Insert a new metadata into the database

   function Insert_Post
     (Uid         : in String;
      Category_Id : in Id;
      Name        : in String;
      Comment     : in String;
      Pid         : in Id) return Id;
   --  Insert a new post into the database. If Pid /= Empty_Id it is the photo
   --  Id for the new post, otherwise it is a textual post. returns post id.

   procedure Increment_Visit_Counter (Pid : in Id);
   --  Increment a thread visit counter

   function Is_Author (Uid : in String; Pid : in Id) return Boolean;
   --  Returns true whether the user of the post Pid is Uid

   function Is_Revealed (Tid : in Id) return Boolean;
   --  Returns true if the author of the given post is now revealed

   function Get_User_Page (Uid : in String) return Templates.Translate_Set;
   --  Returns user page

   procedure Register_New_User_Email
     (Uid : in String; New_Email : in String);
   --  Update user email

   function Validate_New_User_Email (Uid, Key : in String) return Boolean;
   --  Validate new e-mail for given user

   procedure Update_Page
     (Uid : in String; Content : in String; Content_HTML : in String);
   --  Update a user page

   procedure Update_Rating
     (Uid      : in String;
      Tid      : in Id;
      Criteria : in String;
      Value    : in String);
   --  Update post rating

   function Get_Global_Rating (Tid : in Id) return Templates.Translate_Set;
   --  Get the post global rating

   function Get_User_Rating_On_Post
     (Uid : in String; Tid : in Id) return Templates.Translate_Set;
   --  Get the user rating on a specific post

   function Get_New_Post_Delay
     (Uid : in String; TZ : in String) return Templates.Translate_Set;
   --  Get the delay the user has to wait before he can post

   --  Weekly votes

   procedure Toggle_Vote_Week_Photo (Uid : in String; Tid : in Id);
   --  Set or Reset user Uid vote for photo Tid

   function Has_User_Vote (Uid : in String; Tid : in Id) return Boolean;
   --  Returns True if user Uid has voted for the given photo

   function Get_User_Voted_Photos
     (Uid : in String) return Templates.Translate_Set;
   --  Returns the translate table with the list of all voted photos for the
   --  given user.

   function Register_User (Login, Password, Email : in String) return Boolean;
   --  Register a new user before validation. Returns False if the user cannot
   --  be registered (duplicate login).

   function Validate_User (Login, Key : in String) return Boolean;
   --  Validate a registered user

   procedure User_Preferences
     (Login       : in     String;
      Preferences :    out User_Settings);
   --  Returns the user's preferences for the given user. If no preferences are
   --  set, use the default values.

   procedure Set_CSS_URL_Preferences (Login : in String; URL : in String);
   --  Set css url for the given user

   procedure Set_Filter_Preferences
     (Login  : in String;
      Filter : in Filter_Mode);
   --  Set filter preference for the given user

   procedure Set_Filter_Page_Size_Preferences
     (Login     : in String;
      Page_Size : in Positive);
   --  Set filter preference for the given user

   procedure Set_Filter_Sort_Preferences
     (Login : in String;
      Sort  : in Forum_Sort);
   --  Set sort preference for the given user

   procedure Set_Image_Size_Preferences
     (Login      : in String;
      Image_Size : in Database.Image_Size);
   --  Set image size preference for the given user

   procedure Set_Private_Message_Preferences
     (Login                  : in String;
      Accept_Private_Message : in Boolean);
   --  Set private message preference

   function Get_Stats return Templates.Translate_Set;
   --  Returns global stats used in main page

   function Gen_Cookie (Login : in String) return String;
   --  Generate a new random string for "remember me" authentication

   procedure Register_Cookie (Login : in String; Cookie : in String);
   --  Register a new cookie in database

   function Get_User_From_Cookie (Cookie : in String) return String;
   --  Return user associated with the given cookie (or "")

   procedure Delete_User_Cookies (Login : in String);
   --  Delete user cookies

   procedure Remember (Login : in String; Status : in Boolean);
   --  Should we remember the user with a cookie ?

   procedure Set_Last_Visit (Login : in String; TID : in Id);

private

   Default_User_Settings : constant User_Settings :=
                             User_Settings'
                               (Page_Size              => 10,
                                Filter                 => Seven_Days,
                                Sort                   => Last_Commented,
                                Image_Size             => Max_Size,
                                Accept_Private_Message => False,
                                CSS_URL                =>
                                  Null_Unbounded_String);

   No_User_Data : constant User_Data :=
                    User_Data'
                      (Null_Unbounded_String,
                       Null_Unbounded_String,
                       Null_Unbounded_String,
                       False,
                       Default_User_Settings);

   Empty_Id     : constant Id := 0;

   --  Connection

   type TLS_DBH is record
      Handle    : access DB.Handle'Class;
      Connected : Boolean;
   end record;

   type TLS_DBH_Access is access all TLS_DBH;

   Null_DBH : constant TLS_DBH :=
                TLS_DBH'(Handle => null, Connected => False);

   package DBH_TLS is
     new Ada.Task_Attributes (Attribute => TLS_DBH, Initial_Value => Null_DBH);

   procedure Connect (DBH : in TLS_DBH_Access);
   --  Connect to the database if needed

end V2P.Database;
