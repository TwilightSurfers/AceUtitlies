program AceTests;

{ Console fpcunit runner for Ace's Utilities.

  Build & run:  powershell -ExecutionPolicy Bypass -File tests\run-tests.ps1
  Or manually:  lazbuild -B tests\AceTests.lpi
                tests\bin\AceTests.exe --all --format=plain }

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // LCL widgetset: TBitmap is used by the PDF rendering tests
  Classes, consoletestrunner,
  TestAceCore, TestAcePdf;

type
  TAceTestRunner = class(TTestRunner)
  end;

var
  App: TAceTestRunner;

begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  App := TAceTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'Ace''s Utilities Tests';
    App.Run;
  finally
    App.Free;
  end;
end.
