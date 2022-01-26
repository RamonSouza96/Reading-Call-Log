unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.TabControl, FMX.Edit,System.DateUtils,System.Threading,

  {$IFDEF ANDROID}
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net,
  Androidapi.Helpers,
  Androidapi.JNI.Provider,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  FMX.PhoneDialer,
  FMX.Platform,

   System.Permissions,
   Androidapi.JNI.Os,
  {$ENDIF}
    FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  TFrmMain = class(TForm)
    TabControlAll: TTabControl;
    Permission: TTabItem;
    Rectangle1: TRectangle;
    Layout1: TLayout;
    Text1: TText;
    Rectangle2: TRectangle;
    Image1: TImage;
    Text2: TText;
    Switch1: TSwitch;
    Layout2: TLayout;
    Image2: TImage;
    Text3: TText;
    Switch2: TSwitch;
    Rectangle4: TRectangle;
    BtnNext: TSpeedButton;
    Lista: TTabItem;
    Rectangle7: TRectangle;
    Circle1: TCircle;
    Image5: TImage;
    VertScroll: TVertScrollBox;
    RectHeader: TRectangle;
    Rectangle5: TRectangle;
    Edit1: TEdit;
    Image3: TImage;
    Text4: TText;
    Text5: TText;
    Layout3: TLayout;
    RectGeral: TRectangle;
    Text6: TText;
    RectRecebidas: TRectangle;
    Text7: TText;
    RectEfetuadas: TRectangle;
    Text8: TText;
    ShadowEffect2: TShadowEffect;
    Rectangle10: TRectangle;
    ShadowEffect3: TShadowEffect;
    ShadowEffect1: TShadowEffect;
    ImgSend: TImage;
    ImgCallConnect: TImage;
    ImgReceved: TImage;
    ImgMissed: TImage;
    ImgRecused: TImage;
    ImgSpam: TImage;
    ImgUnknown: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    Procedure CreateCard(ImgCall: TBitmap; NameCall: string; Number: string; Date: string; Zone: string);
    Procedure GetCallLog(vFilter,AName: String);
    procedure Switch1Switch(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure RectEfetuadasTap(Sender: TObject; const Point: TPointF); 
    procedure DeleteAll();
    procedure Edit1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure RectGeralClick(Sender: TObject);
    procedure RectRecebidasClick(Sender: TObject);
    procedure PhoneCall(phoneNumber: string);
    procedure Circle1Click(Sender: TObject);
    procedure ClickCard(Sender: TObject; const Point: TPointF);
    procedure Switch2Switch(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  vTop : Integer;
  vI : Integer;

  vFinishTThread:Boolean;

  iLayout1_X,iLayout1_Y,iLayout2_X,iLayout2_Y: Single;
  iText1_X,iText1_Y,iText2_X,iText2_Y,iText3_X, iText3_Y,
  iText4_X,iText4_Y: Single;
  iImg1_X,iImg1_Y,iImg2_X,iImg2_Y: Single;

implementation

{$R *.fmx}

uses Android.SystemBars;

Procedure TFrmMain.ClickCard(Sender: TObject; const Point: TPointF);
Begin
PhoneCall(TImage(Sender).TagString);
End;

function JavaToDateTime(Value: Int64): TDateTime;
begin
  Result := IncMilliSecond(UnixDateDelta, Value);
end;

Procedure TFrmMain.GetCallLog(vFilter, AName: String);
var
  Cursor     : JCursor;
  Uri        : Jnet_Uri;
  vNumber, vCache_Name,vDuration,vDate,
  vType,vISO,vGeo_Loc : string;
  vBitmapType:TBitmap;
  vTipeCall  : String;
  vCondition1,vCondition2,vCondition3 : String;
  vNameFields: TJavaObjectArray<JString>;

begin

    if vFinishTThread = True then  // verifica se a thread já finalizou
    exit;

    vTop:=-65;
    vI:=0;
    
    Uri:=StrToJURI('content://call_log/calls');// caminho para tabela calls

    vNameFields :=   TJavaObjectArray<JString>.Create(4); {Nome do campo a ser consultado, se tiver null vem todos os campos}
    vNameFields.Items[0] := TJCallLog_Calls.JavaClass.NUMBER;
    vNameFields.Items[1] := TJCallLog_Calls.JavaClass.DATE;
    vNameFields.Items[2] := TJCallLog_Calls.JavaClass.CACHED_NAME;
    vNameFields.Items[3] := TJCallLog_Calls.JavaClass.&TYPE;

    if vFilter <> '*' then Begin
    vCondition1 :=  JStringToString(TJCallLog_Calls.JavaClass.&TYPE)+' = '+vFilter;
    End;

    if AName <> '' then Begin

     vCondition2 :=  JStringToString(TJCallLog_Calls.JavaClass.CACHED_NAME)+' LIKE '+QuotedStr('%' + AName + '%');

     if(vFilter <> '*') and (AName <> '') then
      begin
      vCondition1 := vCondition1 +  ' and ';
      end;

    End;

    vCondition3 := 'DATE DESC';

   {SELECT number, date, name, type FROM calls WHERE (type = 1 AND LIKE '%Amor%') ORDER BY DATE DESC}

    cursor := SharedActivity.getContentResolver.query(Uri, vNameFields, StringToJString(vCondition1+vCondition2), nil, StringToJString(vCondition3));
    DeleteAll(); // limpa scroll

    TThread.CreateAnonymousThread(
    procedure
    begin

      vFinishTThread:=true;

      try

         try

          while (Cursor.moveToNext) do
           begin

              vDate       := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.DATE)));
              vCache_Name := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.CACHED_NAME)));
              vNumber     := JStringToString(cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.NUMBER)));
              vType       := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.&TYPE)));

             {vDuration   := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.DURATION))); }
             {vGeo_Loc    := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.GEOCODED_LOCATION)));}
             {vISO        := JStringToString(Cursor.getString(cursor.getColumnIndex(TJCallLog_Calls.JavaClass.COUNTRY_ISO)));}


              if vNumber <> '' then
              Begin

                vDate:= DateTimeToStr(JavaToDateTime(vDATE.ToInt64 - 7200000));

                case vTYPE.ToInteger of
                1: Begin
                   vBitmapType:= ImgReceved.Bitmap;
                   vTipeCall:='Recebida'; {incoming call}
                   end;

                2: Begin
                   vBitmapType:= ImgSend.Bitmap;
                   vTipeCall  := 'Realizada'; {held call}
                   End;

                3: Begin
                   vBitmapType:= ImgMissed.Bitmap;
                   vTipeCall  := 'Não Atendida'; {not met}
                   End;

                4: Begin
                   vBitmapType:= ImgRecused.Bitmap;
                   vTipeCall  := 'Recusada'; {call refused}
                   End;

                5: Begin
                   vBitmapType:= ImgSpam.Bitmap;
                   vTipeCall  := 'Spam'; {call Spam}
                   End;

                6: begin
                    vBitmapType:= ImgSpam.Bitmap;
                    vTipeCall  := 'Spam'; {call Spam} {Telemarketing cobrança call center etc}
                   end
                   else
                   begin
                    vBitmapType:= ImgUnknown.Bitmap;
                    vTipeCall  := 'Desconhecida'; {unknown}
                   end;

                end;

                if vCACHE_NAME = '' then
                Begin
                 vCACHE_NAME:=vNUMBER;
                end;

                CreateCard(vBitmapType,vCACHE_NAME,vNUMBER,vDATE,' '+vTipeCall);
              end;
           end;

         Except
         end;

      finally
       Cursor.close;
       vFinishTThread:=false;
      end;

    end).Start;

//https://developer.android.com/reference/android/provider/CallLog.Calls

end;

procedure TFrmMain.PhoneCall(phoneNumber: string);
var
  phone: IFMXPhoneDialerService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXPhoneDialerService, IInterface(phone)) then
  begin
    phone.Call(phoneNumber);
    //Para monitorar o estado do telefone, use o evento phone.OnCallStateChanged
  end;
end;

procedure TFrmMain.RectEfetuadasTap(Sender: TObject; const Point: TPointF);
begin
GetCallLog('2','');//Chamadas Efetuadas
end;

procedure TFrmMain.RectGeralClick(Sender: TObject);
begin
GetCallLog('*',''); //Todas as Chamadas
end;

procedure TFrmMain.RectRecebidasClick(Sender: TObject);
begin
GetCallLog('1','');  //Chamadas Recebidas
end;

procedure TFrmMain.Switch1Switch(Sender: TObject);
begin
PermissionsService.RequestPermissions
([JStringToString(TJManifest_permission.JavaClass.READ_CALL_LOG)], nil);
end;

procedure TFrmMain.Switch2Switch(Sender: TObject);
begin
PermissionsService.RequestPermissions
([JStringToString(TJManifest_permission.JavaClass.CALL_PHONE)], nil);
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
begin
Timer1.Enabled:=false;
GetCallLog('*','');
end;

procedure TFrmMain.BtnNextClick(Sender: TObject);
begin
TabControlAll.GotoVisibleTab(1);
Timer1.Enabled:=true;
end;

procedure TFrmMain.Circle1Click(Sender: TObject);
var
   uri: Jnet_Uri;
   Intent: JIntent;
begin
 Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_DIAL);
 TAndroidHelper.Activity.startActivity(Intent);
end;

Procedure TFrmMain.CreateCard(ImgCall: TBitmap; NameCall: string; Number: string; Date: string; Zone: string);
var
iLayout1,iLayout2: TLayout;
iText1,iText2,iText3,iText4: TText;
iImg1 ,iImg2: Timage;
iLine: TLine;
Begin

 inc(vTop,65);
 INC(vI);

   TThread.Synchronize(TThread.CurrentThread,
  procedure
  begin

    iLayout1 := TLayout.Create(VertScroll); //Layout geral
    with iLayout1 do
    begin

      Size.Height := 65;
      if vI = 1 then
      Begin
       Align  := TAlignLayout.Top;
      End else
      Begin
       Position.Y := vTop;
       Position.X := iLayout1_X;
      End;

    end;

    iImg1 := TImage.create(iLayout1); // img type
    with iImg1 do
    begin
      Align                 := TAlignLayout.MostLeft;
      HitTest               := false;
      MultiResBitmap.Height := 128;
      MultiResBitmap.Width  := 128;
      Size.Width            := 34;
      Size.Height           := 22;
      Margins.Top           := 15;
      Margins.Left          := 10;
      Margins.Right         := 15;
      Margins.Bottom        := 15;
      bitmap := ImgCall;
      WrapMode              := TImageWrapMode.Place;
      Parent := iLayout1;

    end;

    iText1:= TText.Create(iLayout1);     //Text Name
    with iText1 do
    begin
      HitTest                 := false;
      Size.Width              := 157;
      Size.Height             := 20;
      Margins.Top             := 5;
      Margins.Bottom          := 2;
      Position.x              := 10;
      Position.y              := 0;
      Text                    := NameCall;
      TextSettings.Font.Size  := 16;
      TextSettings.FontColor  := $FF1E2538;
      TextSettings.VertAlign  := TTextAlign.Center;
      TextSettings.HorzAlign  := TTextAlign.Leading;
      TextSettings.WordWrap   := False;
      Parent                  := iLayout1;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.Top;
      End else
      Begin
       Position.Y := iText1_Y;
       Position.X := iText1_X;
      End;

    end;

    iText2:= TText.Create(iLayout1);  //Text Number
    with iText2 do
    begin
      HitTest                 := false;
      Size.Width              := 157;
      Size.Height             := 15;
      Position.x              := 10;
      Position.y              := 20;
      Text                    := Number;
      TextSettings.Font.Size  := 11.5;
      TextSettings.FontColor  := $FF838282;
      TextSettings.HorzAlign  := TTextAlign.Leading;
      Parent                  := iLayout1;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.top;
      End else
      Begin
       Position.Y := iText2_Y;
       Position.X := iText2_X;
      End;
    end;

    iLayout2 := TLayout.Create(iLayout1); //Layout 2
    with iLayout2 do
    begin
      Size.Width  := 186;
      Size.Height := 48;
      Position.x              := 100;
      Position.y              := 0;
      Parent:=iLayout1;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.MostRight;
      End else
      Begin
       Position.Y := iLayout2_Y;
       Position.X := iLayout2_X;
      End;

    end;

    iText3:= TText.Create(iLayout2);  //Text Date
    with iText3 do
    begin
      HitTest                 := false;
      Size.Width              := 143;
      Size.Height             := 20;
      Margins.Top             := 6;
      Position.x              := 0;
      Position.y              := 0;
      Text                    := Date;
      TextSettings.Font.Size  := 11.5;
      TextSettings.FontColor  := $FF1E2538;
      TextSettings.HorzAlign  := TTextAlign.Leading;
      Parent                  := iLayout2;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.top;
      End else
      Begin
       Position.Y := iText3_Y;
       Position.X := iText3_X;
      End;
    end;

    iImg2 := TImage.create(iLayout2); // img call
    with iImg2 do
    begin
      HitTest               := true;
      MultiResBitmap.Height := 128;
      MultiResBitmap.Width  := 128;
      Margins.Top           := 10;
      Margins.Left          := 10;
      Margins.Right         := 15;
      Margins.Bottom        := 16;
      Size.Width            := 18;
      Size.Height           := 22;
      bitmap                := ImgCallConnect.bitmap;
      WrapMode              := TImageWrapMode.Place;
      Parent                := iLayout2;
      TagString             := Number;
      OnTap                 := ClickCard;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.MostRight;
      End else
      Begin
       Position.Y := iImg2_Y;
       Position.X := iImg2_X;
      End;

    end;

    iText4:= TText.Create(iLayout2);  //Text Zone
    with iText4 do
    begin
      HitTest                 := false;
      AutoSize                := true;
      Size.Width              := 143;
      Size.Height             := 15;
      Margins.Top             := 6;
      Text                    := Zone;
      TextSettings.Font.Size  := 11.5;
      TextSettings.FontColor  := $FF838282;
      TextSettings.HorzAlign  := TTextAlign.Leading;
      Parent                  := iLayout2;

      if vI = 1 then
      Begin
       Align  := TAlignLayout.top;
      End else
      Begin
       Position.Y := iText4_Y;
       Position.X := iText4_X;
      End;

    end;

    iLayout1.Parent:=VertScroll;

      if vI = 1 then
    Begin
     iLayout1_Y:= iLayout1.Position.Y; iLayout1_X:= iLayout1.Position.X;
     iLayout2_Y:= iLayout2.Position.Y; iLayout2_X:= iLayout2.Position.X;
     iImg1_Y   := iImg1.Position.Y;    iImg1_X   := iImg1.Position.X;
     iImg2_Y   := iImg2.Position.Y;    iImg2_X   := iImg2.Position.X;
     iText1_Y  := iText1.Position.Y;   iText1_X  := iText1.Position.X;
     iText2_Y  := iText2.Position.Y;   iText2_X  := iText2.Position.X;
     iText3_Y  := iText3.Position.Y;   iText3_X  := iText3.Position.X;
     iText4_Y  := iText4.Position.Y;   iText4_X  := iText4.Position.X;
    End;

  end);

End;

procedure TFrmMain.DeleteAll();
  var
  i : integer;
  Lay : TLayout;
begin

    try

        for i := VertScroll.ComponentCount - 1 downto 0 do
        begin

            if VertScroll.Components[i].ClassName = 'TLayout' then
            begin
                Lay := TLayout(VertScroll.Components[i]);
                Lay.DisposeOf;
            end;
        end;

    finally

    end;


end;

procedure TFrmMain.Edit1Change(Sender: TObject);
begin
GetCallLog('*',Edit1.Text);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
{$IFDEF ANDROID}
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := $FFFEFFFF;
  TAndroidSystemBars.RemoveSystemBarsBackground(TAlphaColors.White,TAlphaColors.White);
  Padding.Rect := TAndroidSystemBars.TappableInsets;
{$ENDIF}
end;

end.
